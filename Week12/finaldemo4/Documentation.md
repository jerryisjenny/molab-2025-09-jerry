1. Project Overview

Core Philosophy:
This application was created to challenge the societal obsession with "perfect beauty" and the phenomenon of facial dysmorphia. By allowing users to intentionally distort facial features—creating exaggerated eyes, twisted faces, and altered mouths—and transforming these "imperfect" creations into permanent 3D models, the project serves as an artistic commentary on the malleability and subjectivity of human appearance.


2. Development Log: Challenges & Solutions

Phase 1: API Integration (3D Generation)

Problem: Uploading images via multipart/form-data caused server errors (invalid character '-').

Solution: Switched the upload method to a JSON payload containing a Base64 encoded string of the image. This resolved the parsing issue on the API side.

Problem: Generated models were often tilted or rotated incorrectly.

Solution: Added the "symmetry_mode": "auto" parameter to the API request payload, instructing the AI to align the object based on symmetry.

Phase 2: 3D Visualization (iOS Native)

Problem: SceneKit could not directly load the downloaded .glb files, resulting in errno 2 (file not found/cannot open) errors.

Solution: Implemented a dual-strategy viewer:

Prioritized .usdz format (Apple native) if available.

For .glb, used the Model I/O framework (MDLAsset) as a bridge to convert the file into a SceneKit-compatible scene.

Phase 3: Face Editing (Vision & Core Image)

Feature: Needed to distort specific facial features (eyes, mouth, face shape).

Solution: Utilized Apple's Vision framework to detect facial landmarks (pupils, lips) and applied Core Image filters (CIBumpDistortion, CITwirlDistortion) to specific coordinates.

Problem: The image preview would "flash" or resize unpredictably during editing.

Solution: 1.  Logic: Forced the edited UIImage to retain the scale and orientation of the original photo.
2.  UI: Wrapped the image in a ZStack with a fixed-height container and Color.clear placeholder to maintain layout stability.

Phase 4: Camera & UI

Problem: Clicking "Camera" sometimes opened the Photo Library due to state conflicts.

Solution: Refactored the architecture to separate concerns. Used SwiftUI's native PhotosPicker for the gallery and created a dedicated struct CameraView (wrapping UIImagePickerController with .sourceType = .camera) for taking photos.


3. Collaboration & Roles

My Role (Developer):


Implemented the Face Editing logic (Vision + Core Image integration).

Solved the UI flickering and layout stability issues.

Debugged the Camera/Gallery switching logic.



AI Assistant Role (Gemini & Claude):

API Environment: Instructed on how to set up the HTTP request structure for the 3D generation API and handled the JSON/Base64 encoding requirements.

File Formats: Advised on the compatibility differences between .glb and .usdz on iOS, and provided the specific ModelIO import code required to render GLB files in SceneKit.

Face Detection: Detected the specific part of face

4. Key Learnings

iOS 3D Workflow: Learned that while SceneKit is powerful, it requires specific bridges (ModelIO) to handle non-native formats like GLB effectively.

State Management: Discovered that separating conflicting UI states (like Camera vs. Library) into distinct views or strict Enum states is crucial for stability.

Image Processing: Mastered the coordinate conversion between Vision (normalized 0-1) and UIKit (pixels), and the importance of preserving image metadata (scale/orientation) during processing.

5. Future

AR Integration: Allow users to project their distorted 3D heads onto their own faces in real-time using ARKit (Face Tracking).

Animation: Use the API's rigging capabilities (if available) to make the distorted 3D models talk or blink.

Social Gallery: A cloud-based gallery where users can share their "imperfect" creations, voting on the most artistic distortions.

