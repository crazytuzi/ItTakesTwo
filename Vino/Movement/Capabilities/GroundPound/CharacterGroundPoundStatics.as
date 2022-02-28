import Vino.Movement.Components.GroundPound.CharacterGroundPoundComponent;

UFUNCTION()
void LockPlayerInGroundPoundLand(AHazePlayerCharacter Player)
{
	if (Player == nullptr)
		return;

	UCharacterGroundPoundComponent GroundPoundComp = UCharacterGroundPoundComponent::GetOrCreate(Player);
	GroundPoundComp.LockStayInLanding();
}

UFUNCTION()
void UnlockPlayerInGroundPoundLand(AHazePlayerCharacter Player)
{
	if (Player == nullptr)
		return;

	UCharacterGroundPoundComponent GroundPoundComp = UCharacterGroundPoundComponent::GetOrCreate(Player);
	GroundPoundComp.UnlockStayInLanding();
}

UFUNCTION()
void SetPlayerGroundPoundLandCameraShake(AHazePlayerCharacter Player, FHazeCameraImpulse Impulse, TSubclassOf<UCameraShakeBase> CameraShake)
{
	UCharacterGroundPoundComponent GroundPoundComp = UCharacterGroundPoundComponent::GetOrCreate(Player);
	GroundPoundComp.CurrentLandCameraImpulse = Impulse;
	GroundPoundComp.CurrentLandCameraShake = CameraShake;
}

UFUNCTION()
void ResetPlayerGroundPoundLandCameraImpulse(AHazePlayerCharacter Player)
{
	UCharacterGroundPoundComponent GroundPoundComp = UCharacterGroundPoundComponent::GetOrCreate(Player);
	GroundPoundComp.CurrentLandCameraImpulse = GroundPoundComp.DefaultLandCameraImpulse;
	GroundPoundComp.CurrentLandCameraShake = GroundPoundComp.DefaultLandCameraShake;
}
