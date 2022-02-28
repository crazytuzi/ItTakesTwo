import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Clockwork.TimeControlMechanic.TimeControlActorComponent;

class APushableClockBox : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent)
	USceneComponent MovementRoot;

	UPROPERTY(DefaultComponent, Attach = BoxMesh)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartPushingEvent;

	UPROPERTY(DefaultComponent, Attach = MovementRoot)
	UStaticMeshComponent BoxMesh;

	UPROPERTY(DefaultComponent, Attach = MovementRoot)
	UInteractionComponent InteractionPoint;
	default InteractionPoint.MovementSettings.InitializeSmoothTeleport();
	default InteractionPoint.ActionShape.Type = EHazeShapeType::Sphere;
	default InteractionPoint.ActionShape.SphereRadius = 350.f;
	default InteractionPoint.FocusShape.Type = EHazeShapeType::Sphere;
	default InteractionPoint.FocusShape.SphereRadius = 1000.f;
	default InteractionPoint.Visuals.VisualOffset.Location = FVector(0.f, 0.f, 0.f);

	// UPROPERTY(DefaultComponent)
	// UHazeSmoothSyncVectorComponent SyncVectorComp;

	UPROPERTY(DefaultComponent, Attach = MovementRoot)
	UTimeControlActorComponent TimeControlComp;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> PushCapability;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence PushEnter;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence PushMH;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence PushForward;

	UPROPERTY(EditDefaultsOnly)
	UAnimSequence PushExit;

	UPROPERTY()
	float PushSpeed = 250.f;

	UPROPERTY()
	float PushDistance = 1000.f;

	UPROPERTY()
	bool PlayerPushing = false;

	FVector CurrentPlayerInput = FVector::ZeroVector;

	bool bReachedEnd = false;
	private FHazeAudioEventInstance PushingEventInstance;
	private FVector LastLocation;
	private float LastVelocityRtpcValue = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionPoint.DisableForPlayer(Game::GetCody(), n"Cody");
		Capability::AddPlayerCapabilityRequest(PushCapability.Get(), EHazeSelectPlayer::May);
		InteractionPoint.OnActivated.AddUFunction(this, n"OnInteractionActivated");

		SetControlSide(Game::GetMay());
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(PushCapability.Get(), EHazeSelectPlayer::May);
	}


	UFUNCTION()
    void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		InteractionPoint.Disable(n"Used");
		StartPushing(Player);
    }

	UFUNCTION()
	void ReleaseBlock(bool ReachedEnd)
	{
		InteractionPoint.EnableAfterFullSyncPoint(n"Used");
		
		CurrentPlayerInput = FVector::ZeroVector;
		PlayerPushing = false;
		HazeAkComp.HazeStopEvent(PushingEventInstance.PlayingID, 300.f);
	}

    UFUNCTION()
    void StartPushing(AHazePlayerCharacter Player)
    {
        Player.SetCapabilityAttributeObject(n"PushableClockBox", this);
        Player.SetCapabilityActionState(n"PushingClockBox", EHazeActionState::Active);
		PlayerPushing = true;

		LastLocation = BoxMesh.GetWorldLocation();
		if(LastVelocityRtpcValue != 0.f)
		{
			HazeAkComp.SetRTPCValue("Rtpc_Object_Velocity", 0.f);
			LastVelocityRtpcValue = 0.f;
		}

		PushingEventInstance = HazeAkComp.HazePostEvent(StartPushingEvent);
    }

	void UpdatePushDirection(FVector PlayerInput)
    {
		CurrentPlayerInput = PlayerInput;
    }


	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bReachedEnd)
			return;

		// if (HasControl())
		// {
			if(PlayerPushing)
			{
				TimeControlComp.ManuallySetPointInTime(TimeControlComp.PointInTime + (FMath::Clamp(CurrentPlayerInput.X, 0.f, 1.f) * DeltaTime * 0.05f));

				
				if(TimeControlComp.PointInTime >= 0.16f)
				{
					NetReachedEnd();
				}
			}
		// }
		else
		{
			// MovementRoot.SetRelativeLocation(SyncVectorComp.Value);
		}

		SetVelocityRtpc(DeltaTime);
	}

	void SetVelocityRtpc(const float DeltaTime)
	{
		if(!PlayerPushing)
		{
			if(LastVelocityRtpcValue != 0.f)
			{
				HazeAkComp.SetRTPCValue("Rtpc_Object_Velocity", 0.f);
				LastVelocityRtpcValue = 0.f;
			}

			return;
		}

		FVector Location = BoxMesh.GetWorldLocation();

		const float Velocity = (Location - LastLocation).Size() / DeltaTime;
		const float NormalizedVelo = FMath::Clamp(Velocity / PushSpeed, 0.f, 1.f);

		if(NormalizedVelo != LastVelocityRtpcValue)
		{
			HazeAkComp.SetRTPCValue("Rtpc_Object_Velocity", NormalizedVelo);
			LastVelocityRtpcValue = NormalizedVelo;
		}

		LastLocation = Location;
	}

	UFUNCTION(NetFunction)
	void NetReachedEnd()
	{
		bReachedEnd = true;
		InteractionPoint.Disable(n"Done");
		ReachedEndLoc();
	}

	UFUNCTION(BlueprintEvent)
	void ReachedEndLoc() {}

	UFUNCTION(BlueprintEvent)
	void Pushing() {}
}