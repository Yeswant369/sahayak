# google_mlkit_text_recognition references all script recognizers; we bundle
# only Latin. Silence R8 for the scripts we don't ship. (Add the Devanagari
# artifact when Hindi-label OCR lands.)
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
