
/**
 * Helper component for playing world camera shakes at a location.
 * Can be put on an actor just like UForceFeedbackComponent so all
 * you need to do is call Play() on both.
 */
class UWorldCameraShakeComponent : USceneComponent
{
	UPROPERTY(Category = "Camera Shake")
	TSubclassOf<UCameraShakeBase> CameraShake;

	// Cameras inside this radius get the full intensity shake.
	UPROPERTY(Category = "Camera Shake")
	float InnerRadius = 0.f;

	// Cameras outside this radius are not affected.
	UPROPERTY(Category = "Camera Shake")
	float OuterRadius = 0.f;

	// Exponent that describes the shake intensity falloff curve between InnerRadius and OuterRadius. 1.0 is linear.
	UPROPERTY(Category = "Camera Shake")
	float Falloff = 1.f;

	// Scale factor for the camera shake
	UPROPERTY(Category = "Camera Shake")
	float ShakeScale = 1.f;

	// Changes the rotation of shake to point towards epicenter instead of forward. Useful for things like directional hits.
	UPROPERTY(Category = "Camera Shake")
	bool bOrientShakeTowardsEpicenter = false;

	UPROPERTY(Category = "Camera Shake")
	EHazeWorldCameraShakeSamplePosition SamplePosition = EHazeWorldCameraShakeSamplePosition::Player;

	private TPerPlayer<UCameraShakeBase> ShakeInstances;

	// Play the specified camera shake from this world position
	UFUNCTION()
	void Play()
	{
		for (AHazePlayerCharacter Player : Game::Players)
			PlayForPlayer(Player);
	}

	// Play the specified camera shake from this world position on a specific player
	UFUNCTION()
	void PlayForPlayer(AHazePlayerCharacter Player)
	{
		if (Player == nullptr)
			return;
		ShakeInstances[Player] = Player.PlayWorldCameraShake(
			CameraShake.Get(),
			GetWorldLocation(),
			InnerRadius,
			OuterRadius,
			Falloff,
			ShakeScale,
			bOrientShakeTowardsEpicenter,
			SamplePosition
		);
	}

	// Stop the camera shake being played in the world by this component
	UFUNCTION()
	void Stop(bool bImmediately = true)
	{
		for (AHazePlayerCharacter Player : Game::Players)
			StopForPlayer(Player, bImmediately);
	}

	// Stop the camera shake being played in the world by this component on a specific player
	UFUNCTION()
	void StopForPlayer(AHazePlayerCharacter Player, bool bImmediately = true)
	{
		if (Player == nullptr)
			return;
		if (ShakeInstances[Player] != nullptr)
		{
			Player.StopCameraShake(ShakeInstances[Player], bImmediately);
			ShakeInstances[Player] = nullptr;
		}
	}

	// update the shake scale, for active instances, based on world location
	void RefreshShakeLocations()
	{
		for (AHazePlayerCharacter Player : Game::Players)
		{
			if (Player == nullptr)
				continue;
			
			RefreshShakeLocationForPlayer(Player);
		}
	}

	// will update the shake scale for the active instance based on this components world location
	void RefreshShakeLocationForPlayer(AHazePlayerCharacter Player)
	{
		if(ShakeInstances[Player] == nullptr)
			return;

		ShakeInstances[Player].ShakeScale = ShakeScale;

		ShakeInstances[Player].ShakeScale *= Player.CalculateWorldCameraShakeFraction(
			GetWorldLocation(),
			InnerRadius,
			OuterRadius,
			Falloff,
			SamplePosition
		);
	}

	// whether we've played a shake for this player or not
	bool HasActiveInstance(AHazePlayerCharacter Player)
	{
		return ShakeInstances[Player] != nullptr;
	}

};
