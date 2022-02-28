enum EPianoKeyType
{
	Black,
	White,
}

class UPianoKeyboardDataAsset : UDataAsset
{
	// Sounds for each key when pressed (played at location offset from key). In a piano this will be the sound the strings make when hit by the hammer.
	UPROPERTY()
	TArray<UAkAudioEvent> Notes;

	// Sounds for each key when jumped upon (played at location offset from key). If empty, use regular note.
	UPROPERTY()
	TArray<UAkAudioEvent> JumpNotes;

	// Sounds for keys themselves when pressed. Played at key location, not offset.
	UPROPERTY()
	UAkAudioEvent KeyPressSound;

	// Sounds for keys themselves when pressed by jump. Played at key location, not offset.
	UPROPERTY()
	UAkAudioEvent KeyPressJumpSound;

	// Sounds for keys themselves when released. Played at key location, not offset.
	UPROPERTY()
	UAkAudioEvent KeyReleaseSound;

	// Sound when a key is groundpounded. Played at location of pounding player.
	UPROPERTY()
	UAkAudioEvent GroundPounded;

	// Sound for the hammer when hitting the string, played at location offset from key. 
	UPROPERTY()
	UAkAudioEvent HammerHitSound;

	// Sound for the hammer when lifting from the string, played at location offset from key. 
	UPROPERTY()
	UAkAudioEvent HammerReleaseSound;

	// Key configuration (will repeat to encompass all keys)
	UPROPERTY()
	TArray<EPianoKeyType> Configuration;

	// Mesh for the black keys
	UPROPERTY()
	UStaticMesh BlackKeyMesh;

	// Mesh for white key without any neighbouring black keys
	UPROPERTY()
	UStaticMesh WhiteKeyMesh_Blank;

	// Mesh for white key to the left of a black key
	UPROPERTY()
	UStaticMesh WhiteKeyMesh_Left;

	// Mesh for white key in between two black keys
	UPROPERTY()
	UStaticMesh WhiteKeyMesh_Middle;

	// Mesh for white key to the right of a black key
	UPROPERTY()
	UStaticMesh WhiteKeyMesh_Right;

	// Offset for each black key following the previous white key
	UPROPERTY()
	FVector BlackKeyOffset = FVector(0.f, -50.f, -10.f); // The -10 is a hack to allow player step up from a down pressed white key. Remove if we adjust model.

	// Offset for each white key following the previous white key (we currently assume black keys are always squeezed in between white keys)
	UPROPERTY()
	FVector WhiteKeyOffset = FVector(0.f, -100.f, 0.f);

	// What angle in degrees keys should pitch at when touched by player
	UPROPERTY()
	float PressedAngle = -4.f;	

	// All black keys will be scaled by this
	UPROPERTY()
	FVector BlackKeyScale = FVector::OneVector;
}