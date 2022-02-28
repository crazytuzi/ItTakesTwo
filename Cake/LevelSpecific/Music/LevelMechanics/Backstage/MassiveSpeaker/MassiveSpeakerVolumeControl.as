import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.MassiveSpeaker.MassiveSpeakerVolumeControlFeature;
import Vino.Pickups.PickupActor;

event void FMassiveVolumeControlEvent();
class AMassiveSpeakerVolumeControl : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USplineComponent Spline;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UInteractionComponent Interaction;

	UPROPERTY(DefaultComponent, Attach = Interaction)
	UInteractionComponent FakeInteraction;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UHazeAkComponent HazeAkComp;

	UPROPERTY()
	float Progress;

	UPROPERTY()
	float ProgressAcceleration = 1.f;

	UPROPERTY()
	float PushBackAcceleration = 50.f;

	UPROPERTY()
	FMassiveVolumeControlEvent OnStartedInteract;

	UPROPERTY()
	FMassiveVolumeControlEvent OnEndedInteract;

	UPROPERTY()
	FMassiveVolumeControlEvent OnHit90Percent;

	UPROPERTY()
	APickupActor Speaker;

	bool bMovedLastFrame;
	float CurrentSpeed;
	bool bSent90PercentEvent;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent ProgressSync;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent InputSync;

	UPROPERTY()
	AHazePlayerCharacter PushingPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapability(n"MassiveSpeakerVolumeControlInteractedCapability");
		AddCapability(n"MassiveSpeakerVolumeControlPushedBackCapability");
		AddCapability(n"MassiveSpeakerVolumeControlRetractCapability");
		AddCapability(n"MassiveSpeakerVolumeControlMoveCapability");

		Speaker.OnPickedUpEvent.AddUFunction(this , n"OnPickedupSpeaker");
		Speaker.OnPutDownEvent.AddUFunction(this , n"OnPutDownSpeaker");
		Interaction.OnActivated.AddUFunction(this, n"OnInteractionActivated");

		FHazeTriggerCondition Condition;
		Condition.bDisplayVisualsWhileDisabled = true;
		Condition.bOnlyCheckOnPlayerControl = false;
		Condition.Delegate.BindUFunction(this, n"CanInteractWith");

		FakeInteraction.AddTriggerCondition(n"Reason?", Condition);

		ProgressSync.OverrideControlSide(Game::GetCody());
		InputSync.OverrideControlSide(Game::GetCody());

		SetControlSide(Game::GetCody());
	}

	UFUNCTION()
	bool CanInteractWith(UHazeTriggerComponent Comp, AHazePlayerCharacter _Player)
	{
		return false;
	}

	UFUNCTION()
	void OnPickedupSpeaker(AHazePlayerCharacter PlayerCharacter, APickupActor PickupableActor)
	{
		Interaction.Disable(n"SpeakerPickedUp");
		FakeInteraction.Enable(n"SpeakerPickedUp");
	}

	UFUNCTION()
	void OnPutDownSpeaker(AHazePlayerCharacter PlayerCharacter, APickupActor PickupableActor)
	{
		Interaction.Enable(n"SpeakerPickedUp");
		FakeInteraction.Disable(n"SpeakerPickedUp");
	}

	UFUNCTION()
	float GetProgressPercentage() property
	{
		return Progress / Spline.SplineLength;
	}

    UFUNCTION()
    void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
	{
		Player.SetCapabilityAttributeObject(n"VolumeController", this);
		PushingPlayer = Player;
		OnStartedInteract.Broadcast();
	}

	UFUNCTION()
	void PushBack()
	{
		SetCapabilityActionState(n"PushedBack", EHazeActionState::Active);
	}

	UFUNCTION()
	void StopMovement()
	{
		SetCapabilityActionState(n"StopMoving", EHazeActionState::Active);
	}

	UFUNCTION()
	void ForceExit()
	{
		if (PushingPlayer != nullptr)
		{
			PushingPlayer.SetCapabilityActionState(n"ForceExit", EHazeActionState::Active);
			OnEndedInteract.Broadcast();
		}
	}

	UFUNCTION()
	void Move(float Dot, float OverrideProgressAcceleration, float Clamp = 5.f)
	{
		if (Dot != 0)
		{
			bMovedLastFrame = true;
		}
		else
		{
			bMovedLastFrame = false;
		}

		CurrentSpeed += Dot * OverrideProgressAcceleration * ActorDeltaSeconds;
		CurrentSpeed = FMath::Clamp(CurrentSpeed, -Clamp, Clamp);

		float CurrentSpeedNormalized = FMath::GetMappedRangeValueClamped(FVector2D(-15, 15), FVector2D(-1, 1), CurrentSpeed);
		HazeAkComp.SetRTPCValue("Rtpc_World_Music_Backstage_Interactable_MassiveSpeakerVolumeControl_Speed", CurrentSpeedNormalized);

		if (GetProgressPercentage() > 0.9 && !bSent90PercentEvent)
		{
			OnHit90Percent.Broadcast();
			bSent90PercentEvent = true;
		}
	}
}