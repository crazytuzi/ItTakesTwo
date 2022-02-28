import Vino.Movement.Components.MovementComponent;
import Vino.Interactions.InteractionComponent;
import Vino.Camera.Actors.KeepInViewCameraActor;

settings SnailRaceMovementSettings for UMovementSettings
{
	SnailRaceMovementSettings.WalkableSlopeAngle = 10.f;
	SnailRaceMovementSettings.StepUpAmount  = 0.f;
	//SnailRaceMovementSettings.GravityMultiplier = 200.f;
}

class ASnailRaceSnailActor : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComponent;
	default MoveComponent.DefaultMovementSettings = SnailRaceMovementSettings;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;
	default CrumbComponent.SyncIntervalType = EHazeCrumbSyncIntervalType::VeryHigh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCapsuleComponent CapsuleComponent;

	UPROPERTY(DefaultComponent , Attach = Body)
	USceneComponent RidingPosition;

	UPROPERTY()
	UHazeCapabilitySheet SnailSheet;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCharacterSkeletalMeshComponent Body;

	UPROPERTY(BlueprintReadOnly)
	AHazePlayerCharacter RidingPlayer;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StartSnailMoveAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StopSnailMoveAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent CollidedAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent DashVocalAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent MayJumpOnAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent CodyJumpOnAudioEvent;

	UPROPERTY()
	FRuntimeFloatCurve AccelerationCurve;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ImpactForceFeedback;

	UPROPERTY()
	bool IsCodySnail = false;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SqueezeSync;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 6000.f;


	FHazeAcceleratedFloat SnailSpeed;
	FVector DesiredMoveDirection;

	float SnailBoost;
	float SquishValue;
	bool bBlockSnailValue;

	UPROPERTY()
	bool bIsStunned;
	
	UFUNCTION(NetFunction)
	void NetSetBlockSnailValue(bool Value)
	{
		bBlockSnailValue = Value;
	}

	void Reset()
	{
		SnailBoost = 0;
		SquishValue = 0;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComponent.Setup(CapsuleComponent);
		DisableMovementComponent(this);
		Capability::AddPlayerCapabilitySheetRequest(SnailSheet);

		if(IsCodySnail)
		{
			SetControlSide(Game::Cody);
		}
		else if (!IsCodySnail )
		{
			SetControlSide(Game::May);
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilitySheetRequest(SnailSheet);
	}

	UFUNCTION()
	void SetDesiredMoveDir(FVector MoveDir)
	{
		DesiredMoveDirection = MoveDir;
	}

	UFUNCTION()
	void BoostSnail()
	{
		SetCapabilityActionState(n"BoostSnail", EHazeActionState::Active);
	}

    UFUNCTION()
    void StartRidingSnail(AHazePlayerCharacter Player)
    {
		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.Movement = EHazeActorReplicationSyncTransformType::NoMovement;
		CrumbParams.AddObject(n"Player", Player);
		CrumbComponent.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"Crumb_SetControlSide"), CrumbParams);
    }

	UFUNCTION(NotBlueprintCallable)
	void Crumb_SetControlSide(FHazeDelegateCrumbData CrumbData)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"Player"));
		RidingPlayer = Player;
		Player.SetCapabilityAttributeObject(n"RidingSnail", this);


		if (HasControl())
		{
			SqueezeSync.Value = SquishValue;	
		}
	}
}