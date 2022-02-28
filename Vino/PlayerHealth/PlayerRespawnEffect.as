import Vino.PlayerHealth.PlayerGenericEffect;

delegate void FOnRespawnTriggered(AHazePlayerCharacter Player);

struct FPlayerRespawnEvent
{
	FVector RelativeLocation;
	FRotator Rotation;
	USceneComponent LocationRelativeTo;
	TSubclassOf<UPlayerRespawnEffect> RespawnEffect;
	FOnRespawnTriggered OnRespawn;

	FVector GetWorldLocation() const
	{
		if (LocationRelativeTo != nullptr)
			return LocationRelativeTo.WorldTransform.TransformPositionNoScale(RelativeLocation);
		return RelativeLocation;
	}
};

UCLASS(Abstract)
class UPlayerRespawnEffect : UPlayerGenericEffect
{
	bool bRespawnTriggered = false;

    // If set, the player will not be able to take any additional damage while this effect is active
    UPROPERTY()
    bool bInvulnerableDuringEffect = true;

	UFUNCTION()
	void TriggerRespawn()
	{
		bRespawnTriggered = true;
	}

	void TeleportToRespawnLocation(FPlayerRespawnEvent Event)
	{
        Player.MovementComponent.SetControlledComponentTransform(
			InLocation = Event.GetWorldLocation(),
			InRotation = Event.Rotation
		);

		Player.MovementComponent.SetVelocity(FVector::ZeroVector);

		// If a player had a active offset when they died then the mesh would lerp to the spawn location instead of snapping there.
		Player.RootOffsetComponent.ResetWithTime(0.f);
	}

	void OnPerformRespawn(FPlayerRespawnEvent Event)
	{
		BP_OnPerformRespawn(Event);
	}

	UFUNCTION(BlueprintEvent)
	void BP_OnPerformRespawn(FPlayerRespawnEvent Event) {}
};
