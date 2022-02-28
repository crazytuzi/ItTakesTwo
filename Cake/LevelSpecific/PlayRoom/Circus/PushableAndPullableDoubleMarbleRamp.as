import Peanuts.Spline.SplineComponent;
import Peanuts.Audio.AudioStatics;
import Vino.Interactions.InteractionComponent;

UCLASS(Abstract)
class APushableAndPullableDoubleMarbleRamp : AHazeActor
{
	

    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UHazeSplineComponent HazeSpline;

    UPROPERTY(DefaultComponent, Attach = Root)
    USceneComponent Base;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent PlatformMoveDistanceSync;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent FrontPlayerPushSync;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent BackPlayerPushSync;

    UPROPERTY(DefaultComponent, Attach = Base)
	UInteractionComponent BackInteraction;
    default BackInteraction.RelativeRotation = FRotator(0.f, 0.f, 0.f);
    default BackInteraction.RelativeLocation = FVector(-230.f, 0.f, 0.f);

    UPROPERTY(DefaultComponent, Attach = Base)
    UInteractionComponent FrontInteraction;
    default FrontInteraction.RelativeRotation = FRotator(0.f, 180.f, 0.f);
    default FrontInteraction.RelativeLocation = FVector(840.f, 0.f, 0.f);

    UPROPERTY(DefaultComponent, Attach = Base)
    UArrowComponent PushDirection;
    default PushDirection.RelativeRotation = FRotator(0.f, -90.f, 0.f);

    float BackPushPower;
    float FrontPushPower;
    float TotalPushPower;
	float MoveDelta;

	FHazeAcceleratedFloat Speed;
    
    UPROPERTY()
    float MoveLerpSpeed = 5;

	UPROPERTY()
	float MoveSpeed = 10;

	bool bLastMoveWasBlocked = true;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StartDraggingEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StopDraggingEvent;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	FHazeAudioEventInstance DragRampEventInstance;

    UPROPERTY()
    AHazePlayerCharacter PlayerAtFront;
    UPROPERTY()
    AHazePlayerCharacter PlayerAtBack;

	// Audio!
	UFUNCTION(BlueprintPure)
	float GetMovespeedNormalized() property
	{
		return FMath::Abs((TotalPushPower * MoveSpeed) / (MoveSpeed * 3.f));
	}

	// Audio!
	UFUNCTION(BlueprintPure)
	int NumCharactersPulling()
	{
		if (PlayerAtBack != nullptr && PlayerAtFront != nullptr)
		{
			return 2;
		}

		if (PlayerAtBack != nullptr || PlayerAtFront != nullptr)
		{
			return 1;
		}

		return 0;
	}


    bool FrontInteracitonActivated;
    bool BackInteracitonActivated;

	UPROPERTY()
	TSubclassOf<UHazeCapability> RequiredCapabilityType;

	float DesiredDistanceAlongSpline = 0;

    UPROPERTY()
    bool StartAtEnd;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        SetupTriggerComponent();

		Capability::AddPlayerCapabilityRequest(RequiredCapabilityType.Get());

		DesiredDistanceAlongSpline = 0.f;
        Base.SetWorldLocation(HazeSpline.GetLocationAtDistanceAlongSpline((DesiredDistanceAlongSpline), ESplineCoordinateSpace::World)); 
    }

	void SetupTriggerComponent()
	{
		FHazeTriggerActivationDelegate BackInteractionDelegate;
		BackInteractionDelegate.BindUFunction(this, n"BackInteractionActivated");
		BackInteraction.AddActivationDelegate(BackInteractionDelegate);

        FHazeTriggerActivationDelegate FrontInteractionDelegate;
        FrontInteractionDelegate.BindUFunction(this, n"FrontInteractionActivated");
        FrontInteraction.AddActivationDelegate(FrontInteractionDelegate);
	}

    UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(RequiredCapabilityType.Get());
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		UpdateMovement(DeltaTime);
	}

	void UpdateMovement(float DeltaTime)
	{
		float DistanceAlongSpline = HazeSpline.GetDistanceAlongSplineAtWorldLocation(Base.WorldLocation);
		
		MoveDelta = DistanceAlongSpline - DesiredDistanceAlongSpline;
		bool bCanMoveInDirection = 
			!(FMath::IsNearlyZero(DistanceAlongSpline, 0.001f) && DesiredDistanceAlongSpline < 0) &&
			!(FMath::IsNearlyEqual(DistanceAlongSpline, HazeSpline.SplineLength, 0.001f) && DesiredDistanceAlongSpline >= HazeSpline.SplineLength);
		
		// Stop the looping if it can't move any longer.
		if ((!bCanMoveInDirection || FMath::IsNearlyZero(DistanceAlongSpline - DesiredDistanceAlongSpline, 0.01f)) 
			&& !bLastMoveWasBlocked)
		{
			HazeAkComp.HazePostEvent(StopDraggingEvent);
			bLastMoveWasBlocked = true;
		}
		else if (bCanMoveInDirection && FMath::Abs(DistanceAlongSpline - DesiredDistanceAlongSpline) > 0.01f && bLastMoveWasBlocked)
		{
			HazeAkComp.HazePostEvent(StartDraggingEvent);
			bLastMoveWasBlocked = false;
		}

		HazeAkComp.SetRTPCValue(HazeAudio::RTPC::MoveObjectVelocity, HazeAudio::NormalizeRTPC01((DesiredDistanceAlongSpline-DistanceAlongSpline), -10.f, 10.f), 0);
		DistanceAlongSpline = DesiredDistanceAlongSpline;
		
		FVector NewWorldLocation = HazeSpline.GetLocationAtDistanceAlongSpline((DistanceAlongSpline), ESplineCoordinateSpace::World);
		Base.SetWorldLocation(NewWorldLocation);
	}

	bool IsBlockedMove(float PushDir)
	{
		float DistanceAlongSpline = HazeSpline.GetDistanceAlongSplineAtWorldLocation(Base.WorldLocation);

		if (DistanceAlongSpline == HazeSpline.SplineLength && PushDir > 0)
		{
			return true;
		}

		else if (DistanceAlongSpline == 0 && PushDir < 0)
		{
			return true;
		}

		return false;
	}

    UFUNCTION(BlueprintCallable)
    void CheckPushingAndPulling(float DeltaTime)
    {
        if(FrontInteracitonActivated || BackInteracitonActivated || TotalPushPower != 0)
        {
			TotalPushPower = FrontPushPower + BackPushPower;

			bool bIsBlockedMove = IsBlockedMove(TotalPushPower);

			if (FMath::Abs(TotalPushPower) > 0.1f)
			{
				if (bIsBlockedMove)
				{
					Speed.Value = 0;
					Speed.Velocity = 0;
				}
			}

			else if(!bLastMoveWasBlocked)
			{
				if(FMath::Abs(TotalPushPower) > 0.1f && (FMath::Abs(TotalPushPower) < 0.1f) || bIsBlockedMove)
				{
					bLastMoveWasBlocked = true;
				}
			}

			if (FMath::Abs(TotalPushPower) > 1.f)
			{
				TotalPushPower *= 1.7f; 
			}

			if (HasControl())
			{
				float CurrentDist = HazeSpline.GetDistanceAlongSplineAtWorldLocation(Base.WorldLocation);

				if(!bIsBlockedMove)
				{
					Speed.AccelerateTo(TotalPushPower * MoveSpeed * 0.025f, 0.35f, DeltaTime);
					CurrentDist += Speed.Value;
				}

				PlatformMoveDistanceSync.Value = CurrentDist;
				DesiredDistanceAlongSpline = CurrentDist;
			}

			else
			{
				DesiredDistanceAlongSpline = PlatformMoveDistanceSync.Value;
			}
		}

		if(PlayerAtFront != nullptr && PlayerAtFront.HasControl())
        {
			FrontPlayerPushSync.Value = FrontPushPower;
        }

		else if (PlayerAtFront != nullptr && !PlayerAtFront.HasControl())
		{
			FrontPushPower = FrontPlayerPushSync.Value;
		}

        if(PlayerAtBack != nullptr && PlayerAtBack.HasControl())
        {
			BackPlayerPushSync.Value = BackPushPower;
        }

		else if(PlayerAtBack != nullptr && !PlayerAtBack.HasControl())
		{
			BackPushPower = BackPlayerPushSync.Value;
		}
    }

    void UpdatePushPower(AHazePlayerCharacter Player, FVector MoveDirection)
    {
		if (Player.HasControl())
		{
			if(Player == PlayerAtFront)
			{
				FrontPushPower = MoveDirection.DotProduct(ActorForwardVector);

			}
			else
			{
				BackPushPower = MoveDirection.DotProduct(ActorForwardVector);
			}
		}
    }

    UFUNCTION(NotBlueprintCallable)
	void BackInteractionActivated(UHazeTriggerComponent Component, AHazePlayerCharacter Player)
    {
        Player.SetCapabilityAttributeObject(n"DoubleRamp", this);
        Player.SetCapabilityAttributeObject(n"Interaction", Component);
        Player.SetCapabilityActionState(n"PushingDoubleRamp", EHazeActionState::Active);
        Component.Disable(n"Interacted");
        BackInteracitonActivated = true;
        PlayerAtBack = Player;
		BackPlayerPushSync.OverrideControlSide(Player);

		Player.SmoothSetLocationAndRotation(BackInteraction.WorldLocation, BackInteraction.WorldRotation);
    }

    UFUNCTION(NotBlueprintCallable)
	void FrontInteractionActivated(UHazeTriggerComponent Component, AHazePlayerCharacter Player)
    {
        Player.SetCapabilityAttributeObject(n"DoubleRamp", this);
        Player.SetCapabilityAttributeObject(n"Interaction", Component);
        Player.SetCapabilityActionState(n"PushingDoubleRamp", EHazeActionState::Active);
        Component.Disable(n"Interacted");
        FrontInteracitonActivated = true;
        PlayerAtFront = Player;
		Player.SmoothSetLocationAndRotation(FrontInteraction.WorldLocation, FrontInteraction.WorldRotation);
		
		FrontPlayerPushSync.OverrideControlSide(Player);
    }

    void ReleaseRamp(UHazeTriggerComponent Interaction, AHazePlayerCharacter Player)
    {
        Interaction.Enable(n"Interacted");
        if(Player == PlayerAtFront)
        {
            FrontInteracitonActivated = false;
			FrontPushPower = 0;
            PlayerAtFront = nullptr;
        }
        else
        {
			BackPushPower = 0;
            BackInteracitonActivated = false;
            PlayerAtBack = nullptr;
        }
    }

    void ResetPushPower(AHazePlayerCharacter Player)
    {
        if(Player == PlayerAtFront)
        {
            FrontPushPower = 0.f;
        }
        else
        {
            BackPushPower = 0.f;
        }
    }
}