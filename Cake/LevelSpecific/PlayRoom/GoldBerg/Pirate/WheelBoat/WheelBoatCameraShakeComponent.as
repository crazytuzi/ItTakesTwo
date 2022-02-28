enum ECameraReactorFocusPlayer
{
	May,
	Cody
}

class UWheelBoatCameraShakeComponent : UActorComponent
{
	UPROPERTY(Category = "Setup")
	bool bIsActivated;

	UPROPERTY(Category = "Setup")
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY(Category = "Setup", ShowOnActor)
	ECameraReactorFocusPlayer CameraReactorFocusPlayer;

	UFUNCTION()
	void CameraReaction()
	{
		if (!bIsActivated)
			return;

		if (CameraReactorFocusPlayer == ECameraReactorFocusPlayer::May)
			Game::May.PlayCameraShake(CameraShake, 1.3f);
		else
			Game::Cody.PlayCameraShake(CameraShake, 1.3f);
	}
}