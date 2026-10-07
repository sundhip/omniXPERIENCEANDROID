import os
import uuid
import math
import logging
from typing import Dict, Any, Tuple, Optional, List
import numpy as np
import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision

logger = logging.getLogger(__name__)

class FaceAnalysisService:
    """
    Production Computer Vision service for Facial Geometry, Skin Tone & Hair Analysis.
    Uses Google MediaPipe Face Detector (BlazeFace) for multi-face count validation
    and MediaPipe Face Landmarker for 478 3D geometric landmarks and CIELAB color science.
    Privacy-First: Raw landmarks are strictly ephemeral (processed in memory, then discarded).
    """

    def __init__(self, model_dir: Optional[str] = None):
        if model_dir is None:
            base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
            model_dir = os.path.join(base_dir, "models")
        
        self.model_dir = model_dir
        self.landmarker_path = os.path.join(model_dir, "face_landmarker.task")
        self.detector_path = os.path.join(model_dir, "blaze_face_short_range.tflite")
        self._landmarker = None
        self._detector = None
        self._init_models()

    def _init_models(self):
        # 1. Initialize BlazeFace detector for robust face count detection
        if os.path.exists(self.detector_path):
            try:
                det_base = python.BaseOptions(model_asset_path=self.detector_path)
                det_opts = vision.FaceDetectorOptions(base_options=det_base, min_detection_confidence=0.45)
                self._detector = vision.FaceDetector.create_from_options(det_opts)
                logger.info("MediaPipe BlazeFace detector initialized.")
            except Exception as e:
                logger.error(f"Failed to initialize BlazeFace detector: {e}")

        # 2. Initialize FaceLandmarker for 478 3D geometric landmarks
        if os.path.exists(self.landmarker_path):
            try:
                lm_base = python.BaseOptions(model_asset_path=self.landmarker_path)
                lm_opts = vision.FaceLandmarkerOptions(
                    base_options=lm_base,
                    running_mode=vision.RunningMode.IMAGE,
                    num_faces=5,
                    min_face_detection_confidence=0.45,
                    min_face_presence_confidence=0.45
                )
                self._landmarker = vision.FaceLandmarker.create_from_options(lm_opts)
                logger.info("MediaPipe FaceLandmarker initialized.")
            except Exception as e:
                logger.error(f"Failed to initialize FaceLandmarker: {e}")

    def validate_image_bytes(self, image_bytes: bytes) -> Tuple[bool, Optional[str], Dict[str, Any], Optional[np.ndarray]]:
        """
        Validates image presence, file size, decoding, resolution, blur, brightness, and contrast.
        Returns (is_valid, error_reason, quality_metrics, decoded_bgr_image).
        """
        if not image_bytes or len(image_bytes) == 0:
            return False, "No image data was provided.", {}, None
        
        # Max file size: 10 MB
        if len(image_bytes) > 10 * 1024 * 1024:
            return False, "Image size exceeds 10 MB limit. Please select a smaller photo.", {}, None

        # Decode image using OpenCV
        np_arr = np.frombuffer(image_bytes, np.uint8)
        img_bgr = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
        if img_bgr is None:
            return False, "The file could not be decoded. Please provide a valid JPEG, PNG, or WebP photo.", {}, None

        h, w = img_bgr.shape[:2]
        
        # Resolution validation
        if w < 200 or h < 200:
            return False, f"Image resolution is too low ({w}x{h}). Minimum required resolution is 200x200.", {}, None

        # Convert to grayscale for quality metrics
        gray = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2GRAY)

        # 1. Blur detection via Laplacian variance
        laplacian_var = float(cv2.Laplacian(gray, cv2.CV_64F).var())
        is_blurry = laplacian_var < 35.0

        # 2. Brightness detection via mean grayscale intensity
        mean_brightness = float(np.mean(gray))
        is_too_dark = mean_brightness < 38.0
        is_too_bright = mean_brightness > 235.0

        # 3. Contrast detection via standard deviation
        contrast_std = float(np.std(gray))
        is_low_contrast = contrast_std < 18.0

        quality_score = min(1.0, max(0.1, (
            (min(laplacian_var, 300.0) / 300.0) * 0.4 +
            (1.0 - abs(mean_brightness - 128.0) / 128.0) * 0.3 +
            (min(contrast_std, 80.0) / 80.0) * 0.3
        )))

        quality_metrics = {
            "resolution": f"{w}x{h}",
            "width": w,
            "height": h,
            "blur_variance": round(laplacian_var, 2),
            "brightness": round(mean_brightness, 2),
            "contrast": round(contrast_std, 2),
            "quality_score": round(quality_score, 2)
        }

        if is_too_dark:
            return False, "The photo is too dark. Try taking the photo in brighter lighting.", quality_metrics, None

        if is_too_bright:
            return False, "The photo is overexposed. Try taking the photo with softer, more balanced lighting.", quality_metrics, None

        if is_blurry:
            return False, "The photo appears too blurry. Please try again with a steadier shot.", quality_metrics, None

        if is_low_contrast:
            return False, "The photo has very low contrast. Please ensure clear lighting.", quality_metrics, None

        return True, None, quality_metrics, img_bgr

    def analyze_photo(self, image_bytes: bytes, user_id: str, uploads_dir: str) -> Dict[str, Any]:
        """
        Executes full real computer-vision analysis pipeline:
        Validation -> Face Detection -> Landmark Geometry -> Face Shape -> Skin Tone -> Hair Analysis.
        Landmarks are ephemeral and discarded after feature extraction.
        """
        # 1. Validate image
        is_valid, error_msg, quality_metrics, img_bgr = self.validate_image_bytes(image_bytes)
        if not is_valid:
            return {
                "success": False,
                "error": error_msg,
                "quality_metrics": quality_metrics,
                "user_action": "Try Another Photo"
            }

        if self._landmarker is None:
            self._init_models()
            if self._landmarker is None:
                return {
                    "success": False,
                    "error": "Face analysis model is currently initializing. Please try again in a few seconds.",
                    "user_action": "Retry"
                }

        h, w = img_bgr.shape[:2]
        img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=img_rgb)

        # 2. Face Detection & Count Verification
        face_count = 0
        if self._detector is not None:
            try:
                det_res = self._detector.detect(mp_image)
                face_count = len(det_res.detections)
            except Exception as e:
                logger.warning(f"BlazeFace error: {e}")

        # 3. Run Face Landmarker
        try:
            detection_result = self._landmarker.detect(mp_image)
        except Exception as e:
            logger.error(f"Inference error during face landmarker execution: {e}")
            return {
                "success": False,
                "error": "Failed to analyze photo. Please try a different photo.",
                "user_action": "Try Another Photo"
            }

        faces = detection_result.face_landmarks
        lm_face_count = len(faces)
        final_face_count = max(face_count, lm_face_count)

        # 4. Face Count Constraints
        if final_face_count == 0:
            return {
                "success": False,
                "error": "No face detected. Please ensure your face is clearly visible and facing the camera.",
                "user_action": "Try Another Photo",
                "quality_metrics": quality_metrics
            }

        if final_face_count > 1:
            return {
                "success": False,
                "error": f"We found {final_face_count} faces in the photo. Please upload a photo containing only you.",
                "user_action": "Try Another Photo",
                "quality_metrics": quality_metrics
            }

        # Exactly 1 face
        landmarks = faces[0] # List of 478 NormalizedLandmark (x, y, z in [0, 1])

        # Convert normalized coordinates to pixel space
        pts = [(int(lm.x * w), int(lm.y * h), lm.z * w) for lm in landmarks]

        # 4. Face Size & Pose Validation
        xs = [p[0] for p in pts]
        ys = [p[1] for p in pts]
        min_x, max_x = max(0, min(xs)), min(w, max(xs))
        min_y, max_y = max(0, min(ys)), min(h, max(ys))
        face_area_ratio = float((max_x - min_x) * (max_y - min_y)) / float(w * h)

        if face_area_ratio < 0.035:
            return {
                "success": False,
                "error": "Your face is a little too far away. Please move closer to the camera.",
                "user_action": "Retake",
                "quality_metrics": quality_metrics
            }

        # Pose / Yaw check using nose tip (1) vs cheek boundaries (234, 454)
        nose_x = pts[1][0]
        left_cheek_x = pts[234][0]
        right_cheek_x = pts[454][0]
        cheek_span = max(1, right_cheek_x - left_cheek_x)
        yaw_ratio = abs((nose_x - left_cheek_x) / cheek_span - 0.5)

        if yaw_ratio > 0.28:
            return {
                "success": False,
                "error": "Your face seems turned too far away. Please face the camera directly.",
                "user_action": "Retake",
                "quality_metrics": quality_metrics
            }

        # 5. Facial Geometry & Face Shape Estimation
        face_shape, shape_conf, shape_ratios = self._calculate_face_shape(pts)

        # 6. Skin Tone & Undertone Estimation
        skin_tone, tone_conf, undertone, undertone_conf = self._analyze_skin_tone(img_rgb, pts)

        # 7. Hair Attributes Estimation
        hair_visible, hair_len, hair_tex, hair_conf = self._analyze_hair(img_rgb, pts, min_x, max_x, min_y, max_y)

        # 8. Secure Private Image Storage
        analysis_id = str(uuid.uuid4())
        user_upload_dir = os.path.join(uploads_dir, "visual_profiles", user_id)
        os.makedirs(user_upload_dir, exist_ok=True)
        filename = f"{analysis_id}.jpg"
        file_path = os.path.join(user_upload_dir, filename)
        
        # Save compressed JPEG safely
        cv2.imwrite(file_path, img_bgr, [cv2.IMWRITE_JPEG_QUALITY, 90])

        return {
            "success": True,
            "id": analysis_id,
            "user_id": user_id,
            "source_image_id": filename,
            "face_detected": True,
            "face_count": 1,
            "detected_face_shape": face_shape,
            "confirmed_face_shape": face_shape,
            "face_shape_confidence": shape_conf,
            "detected_skin_tone": skin_tone,
            "confirmed_skin_tone": skin_tone,
            "skin_tone_confidence": tone_conf,
            "detected_skin_undertone": undertone,
            "confirmed_skin_undertone": undertone,
            "skin_undertone_confidence": undertone_conf,
            "hair_visible": hair_visible,
            "detected_hair_length": hair_len,
            "confirmed_hair_length": hair_len,
            "detected_hair_texture": hair_tex,
            "confirmed_hair_texture": hair_tex,
            "hair_confidence": hair_conf,
            "image_quality": quality_metrics,
            "quality_score": quality_metrics["quality_score"],
            "geometric_ratios": shape_ratios,
            "confirmed_by_user": False,
            "analysis_method": "mediapipe_geometry",
            "model_name": "MediaPipe Face Landmarker",
            "model_version": "1.1.0",
            "analysis_version": "1.0.0"
        }

    def _calculate_face_shape(self, pts: List[Tuple[int, int, float]]) -> Tuple[str, float, Dict[str, float]]:
        """
        Calculates face length, cheekbone width, forehead width, jaw width, and proportional ratios.
        Classifies into Oval, Round, Square, Oblong, Heart, Diamond, Triangle, or Unknown.
        """
        # Landmark indices in MediaPipe 478 mesh:
        # Top Forehead (trichion): 10
        # Chin bottom (menton): 152
        # Left cheekbone: 234, Right cheekbone: 454
        # Forehead temples: left 109, right 338
        # Jaw corners (gonion): left 172, right 397
        
        def dist(i1: int, i2: int) -> float:
            p1, p2 = pts[i1], pts[i2]
            return math.sqrt((p1[0] - p2[0])**2 + (p1[1] - p2[1])**2)

        face_length = dist(10, 152)
        face_width = dist(234, 454) # Cheekbone to cheekbone
        forehead_width = dist(109, 338)
        jaw_width = dist(172, 397)

        if face_width <= 0 or forehead_width <= 0 or jaw_width <= 0:
            return "Unknown", 0.0, {}

        length_to_width = face_length / face_width
        jaw_to_forehead = jaw_width / forehead_width
        forehead_to_jaw = forehead_width / jaw_width
        cheek_to_jaw = face_width / jaw_width
        cheek_to_forehead = face_width / forehead_width

        ratios = {
            "length_to_width": round(length_to_width, 3),
            "jaw_to_forehead": round(jaw_to_forehead, 3),
            "forehead_to_jaw": round(forehead_to_jaw, 3),
            "cheek_to_jaw": round(cheek_to_jaw, 3),
            "cheek_to_forehead": round(cheek_to_forehead, 3)
        }

        # Deterministic Classification Rules
        shape = "Oval"
        confidence = 0.82

        if length_to_width >= 1.58:
            shape = "Oblong"
            confidence = min(0.92, 0.75 + (length_to_width - 1.58) * 0.5)
        elif length_to_width < 1.28 and cheek_to_jaw < 1.22:
            if jaw_width / face_width >= 0.82:
                shape = "Square"
                confidence = 0.85
            else:
                shape = "Round"
                confidence = min(0.90, 0.76 + (1.28 - length_to_width) * 0.5)
        elif forehead_to_jaw >= 1.20 and length_to_width >= 1.25:
            shape = "Heart"
            confidence = min(0.90, 0.78 + (forehead_to_jaw - 1.20) * 0.4)
        elif cheek_to_forehead >= 1.18 and cheek_to_jaw >= 1.22:
            shape = "Diamond"
            confidence = 0.84
        elif jaw_to_forehead >= 1.15:
            shape = "Triangle"
            confidence = 0.81
        elif 1.30 <= length_to_width < 1.58:
            shape = "Oval"
            confidence = 0.86
        else:
            shape = "Oval"
            confidence = 0.78

        return shape, round(confidence, 2), ratios

    def _analyze_skin_tone(self, img_rgb: np.ndarray, pts: List[Tuple[int, int, float]]) -> Tuple[str, float, str, float]:
        """
        Samples skin patches from Left Cheek (117), Right Cheek (346), and Forehead (9/107).
        Converts to CIELAB and computes Individual Typology Angle (ITA°).
        Classifies tone (Very Light, Light, Medium, Tan, Deep) and undertone (Warm, Cool, Neutral, Unknown).
        """
        h, w = img_rgb.shape[:2]
        
        # Sample points: Forehead (between 9 and 10), Left cheek (117), Right cheek (346)
        sample_indices = [9, 117, 346]
        face_width = max(10, abs(pts[454][0] - pts[234][0]))
        radius = max(3, int(face_width * 0.04))

        patch_means = []
        for idx in sample_indices:
            cx, cy = pts[idx][0], pts[idx][1]
            y1, y2 = max(0, cy - radius), min(h, cy + radius)
            x1, x2 = max(0, cx - radius), min(w, cx + radius)
            patch = img_rgb[y1:y2, x1:x2]
            if patch.size > 0:
                # Exclude extreme shadow and highlight pixels
                valid_mask = (patch.mean(axis=2) > 30) & (patch.mean(axis=2) < 240)
                if np.any(valid_mask):
                    patch_mean = patch[valid_mask].mean(axis=0)
                else:
                    patch_mean = patch.mean(axis=(0, 1))
                patch_means.append(patch_mean)

        if not patch_means:
            return "Unknown", 0.0, "Unknown", 0.0

        avg_rgb = np.mean(patch_means, axis=0).astype(np.uint8)
        
        # Convert RGB pixel to CIELAB
        lab = cv2.cvtColor(np.uint8([[avg_rgb]]), cv2.COLOR_RGB2LAB)[0][0]
        # OpenCV scale: L* in [0, 255], a* in [0, 255], b* in [0, 255]
        # Standard scale: L in [0, 100], a in [-128, 127], b in [-128, 127]
        L = float(lab[0]) * 100.0 / 255.0
        a = float(lab[1]) - 128.0
        b = float(lab[2]) - 128.0

        # Calculate Individual Typology Angle: ITA° = arctan((L - 50) / b) * (180 / pi)
        if abs(b) > 0.01:
            ita = math.atan2(L - 50.0, b) * (180.0 / math.pi)
        else:
            ita = 90.0 if L >= 50 else -90.0

        # Dermatological / Monk ITA scale
        if ita > 55.0 or L > 70.0:
            tone = "Very Light"
        elif ita > 41.0 or (60.0 < L <= 70.0):
            tone = "Light"
        elif ita > 28.0 or (50.0 < L <= 60.0):
            tone = "Medium"
        elif ita > 10.0 or (40.0 < L <= 50.0):
            tone = "Tan"
        else:
            tone = "Deep"

        # Confidence based on consistency across patches
        if len(patch_means) > 1:
            patch_std = float(np.std([p[0] for p in patch_means]))
            tone_conf = max(0.65, min(0.92, 0.90 - (patch_std / 50.0) * 0.2))
        else:
            tone_conf = 0.72

        # Undertone estimation in CIELAB space
        undertone = "Neutral"
        undertone_conf = 0.75

        if b > 1.25 * a and b > 10.0:
            undertone = "Warm"
            undertone_conf = 0.80
        elif a > b or (a > 11.0 and b < 11.0):
            undertone = "Cool"
            undertone_conf = 0.78
        elif abs(b - a) <= 4.0:
            undertone = "Neutral"
            undertone_conf = 0.76
        else:
            undertone = "Unknown"
            undertone_conf = 0.50

        return tone, round(tone_conf, 2), undertone, round(undertone_conf, 2)

    def _analyze_hair(self, img_rgb: np.ndarray, pts: List[Tuple[int, int, float]], 
                      min_x: int, max_x: int, min_y: int, max_y: int) -> Tuple[bool, str, str, float]:
        """
        Analyzes hair region above forehead and around temples for visibility, length, and texture.
        Uses gradient directionality and spatial frequency filters.
        """
        h, w = img_rgb.shape[:2]
        
        # Hair region: above forehead landmark 10
        forehead_y = pts[10][1]
        top_y = max(0, forehead_y - int((max_y - min_y) * 0.45))
        hair_patch = img_rgb[top_y:forehead_y, min_x:max_x]

        if hair_patch.size == 0 or hair_patch.shape[0] < 5 or hair_patch.shape[1] < 5:
            return True, "Short", "Straight", 0.65

        gray_hair = cv2.cvtColor(hair_patch, cv2.COLOR_RGB2GRAY)
        hair_var = float(np.var(gray_hair))
        
        # Check if bald/buzz (very low texture variance directly above forehead)
        if hair_var < 80.0:
            return False, "Bald/Buzz", "Unknown", 0.80

        # Check hair length (does hair extend below chin landmark 152?)
        chin_y = pts[152][1]
        side_margin = int((max_x - min_x) * 0.15)
        
        # Sample left and right side regions below jaw
        left_side = img_rgb[chin_y:min(h, chin_y + 60), max(0, min_x - side_margin):min_x]
        right_side = img_rgb[chin_y:min(h, chin_y + 60), max_x:min(w, max_x + side_margin)]
        
        has_shoulder_hair = False
        if left_side.size > 50 and right_side.size > 50:
            left_var = float(np.var(left_side))
            right_var = float(np.var(right_side))
            if left_var > 300.0 or right_var > 300.0:
                has_shoulder_hair = True

        if has_shoulder_hair:
            hair_length = "Long"
        elif (max_y - min_y) > 0.6 * h:
            hair_length = "Medium"
        else:
            hair_length = "Short"

        # Texture estimation via Sobel directional gradients
        gx = cv2.Sobel(gray_hair, cv2.CV_64F, 1, 0, ksize=3)
        gy = cv2.Sobel(gray_hair, cv2.CV_64F, 0, 1, ksize=3)
        mag, angle = cv2.cartToPolar(gx, gy, angleInDegrees=True)

        # High variance in gradient angles indicates curly/coily; low variance indicates straight
        angle_hist, _ = np.histogram(angle, bins=8, range=(0, 360))
        angle_entropy = -np.sum((angle_hist / (np.sum(angle_hist) + 1e-6)) * np.log((angle_hist / (np.sum(angle_hist) + 1e-6)) + 1e-6))

        if angle_entropy < 1.4:
            hair_texture = "Straight"
        elif angle_entropy < 1.8:
            hair_texture = "Wavy"
        elif angle_entropy < 2.05:
            hair_texture = "Curly"
        else:
            hair_texture = "Coily"

        hair_conf = 0.74
        return True, hair_length, hair_texture, hair_conf

    def delete_analysis_image(self, user_id: str, filename: str, uploads_dir: str):
        """Safely deletes an analysis photo without leaking file exceptions."""
        try:
            # Prevent path traversal
            safe_filename = os.path.basename(filename)
            target = os.path.join(uploads_dir, "visual_profiles", user_id, safe_filename)
            if os.path.exists(target):
                os.remove(target)
                logger.info(f"Deleted visual profile image for user {user_id}")
        except Exception as e:
            logger.warning(f"Could not delete image file {filename}: {e}")

face_analysis_service = FaceAnalysisService()
