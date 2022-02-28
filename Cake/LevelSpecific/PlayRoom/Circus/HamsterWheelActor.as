import Peanuts.Audio.AudioStatics;
import Vino.Interactions.InteractionComponent;

UCLASS(Abstract)
class AHamsterWheelActor : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    USceneComponent Base;

    UPROPERTY(DefaultComponent, Attach = Base)
    UStaticMeshComponent Wheel; 
    default Wheel.StaticMesh = Asset("/Game/Environment/Props/Fantasy/PlayRoom/Mechanical/HamsterWheek_01_Wheel.HamsterWheek_01_Wheel");
    default Wheel.RelativeRotation = FRotator(0.f, 0.f, 60.f);
    default Wheel.CollisionEnabled = ECollisionEnabled::NoCollision;

    UPROPERTY(DefaultComponent, Attach = Base)
    UStaticMeshComponent Stand;
	default Stand.StaticMesh = Asset("/Game/Environment/Props/Fantasy/PlayRoom/Mechanical/HamsterWheel_01_Stand.HamsterWheel_01_Stand");
    default Stand.CollisionEnabled = ECollisionEnabled::NoCollision;
    
	UPROPERTY(DefaultComponent)
    UInteractionComponent HamsterWheelInteraction;

    UPROPERTY(DefaultComponent, Attach = Base)
	USceneComponent PlayerPositionInWheel;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent AngleSync;
	default AngleSync.NumberOfSyncsPerSecond = 10;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SpeedSync;

	UPROPERTY(DefaultComponent, NotEditable)
    UHazeAkComponent HazeAkComponent;

	UPROPERTY(DefaultComponent)
	USceneComponent JumpoffLocation;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StartRotatingEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StopRotatingEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ImpactEvent;

	float DesiredRotation;
    bool InWheel;

    AHazePlayerCharacter PlayerInWheel;

    UPROPERTY()    
    float InputPower;
    UPROPERTY()    
    float CurrentSpeed;

    float CurrentMoveDirection;

	bool HasBeenInteractedOnce =false;

    UPROPERTY()
    float MaxAngle = 180;

    UPROPERTY()
    float Minangle = 38;

    float WheelAngle = 0;
	bool bHasStopped;

	bool bSoundHitMinOrMaxAngle = false;
	
	UPROPERTY()
	TSubclassOf<UHazeCapability> RequiredCapabilityType;

	UFUNCTION(BlueprintPure)
	float GetCurrentAngle()
	{
		return WheelAngle;
	}

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        HamsterWheelInteraction.OnActivated.AddUFunction(this, n"OnInteracted");

        WheelAngle = Wheel.RelativeRotation.Roll;
		AngleSync.Value = WheelAngle;

		Capability::AddPlayerCapabilityRequest(RequiredCapabilityType.Get());
    }

    UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(RequiredCapabilityType.Get());
	}

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
        if(InWheel)
        {
            UpdateWheelRotation(DeltaTime);
			UpdateWheelBlueprint(DeltaTime);
			HazeAudio::SetPlayerPanning(HazeAkComponent, Cast<AHazeActor>(PlayerInWheel));
        }
		
		else
		{
			RotateWheelToUpposition(DeltaTime);
		}

			if (GetCurrentAngle() >= 154 || GetCurrentAngle() <= Minangle)
			{
				if (!bSoundHitMinOrMaxAngle)
				{
					bSoundHitMinOrMaxAngle = true;
					HazeAkComponent.HazePostEvent(ImpactEvent);
				}
			}
			else
			{
				bSoundHitMinOrMaxAngle = false;
			}

		UpdateWheelAudioLogic();
    }

	void RotateWheelToUpposition(float DeltatTime)
	{
		float WheelAngleLastFrame = WheelAngle;
		WheelAngle = FMath::Lerp(WheelAngle, 90.f, DeltatTime * 0.25f);
		FRotator Rotation = Wheel.GetWorldRotation();
        WheelAngle = FMath::Clamp(WheelAngle, Minangle, MaxAngle);
        Rotation.Roll = WheelAngle;
		AngleSync.Value = WheelAngle;
		Wheel.SetWorldRotation(Rotation);

		CurrentSpeed = FMath::Abs((WheelAngleLastFrame - WheelAngle) / DeltatTime);
	}
	
	UFUNCTION(BlueprintEvent)
	void UpdateWheelBlueprint(float DeltaTime)
	{
		// Deep apologies for the retardedness here. Check the blueprint and cry a little bit.
	}

    void UpdateWheelRotation(float DeltaTime)
    {
		if(PlayerInWheel.HasControl())
		{
			ClampSpeed();
			WheelAngle += CurrentSpeed * DeltaTime;

			FRotator Rotation = Wheel.GetWorldRotation();
			

			if (WheelAngle < Minangle)
			{
				CurrentSpeed = 0;
			}

			WheelAngle = FMath::Clamp(WheelAngle, Minangle, MaxAngle);

			Rotation.Roll = WheelAngle;
			Wheel.SetWorldRotation(Rotation);
			

			CurrentSpeed = FMath::Lerp(CurrentSpeed, 0.f, DeltaTime * 2);
			if (FMath::Abs(CurrentSpeed) < 0.0001)
				CurrentSpeed = 0.f;

			AngleSync.Value = WheelAngle;
			SpeedSync.Value = CurrentSpeed;

			NetSyncSpeedAndRotation(WheelAngle, CurrentSpeed);
		}

		else
		{
			WheelAngle = AngleSync.Value;
			CurrentSpeed = SpeedSync.Value;

			FRotator Rotation = Wheel.GetWorldRotation();
			Rotation.Roll = WheelAngle;

			Wheel.SetWorldRotation(Rotation);
		}
    }

	void UpdateWheelAudioLogic()
	{
		float CurrentSpeedNormalized = CurrentSpeed / 100;
		CurrentSpeedNormalized = FMath::Abs(CurrentSpeedNormalized);

		if (CurrentSpeedNormalized < 0.01f && !bHasStopped)
		{
			bHasStopped = true;
			HazeAkComponent.HazePostEvent(StopRotatingEvent);
		}

		else if(CurrentSpeedNormalized > 0.01f && bHasStopped)
		{
			bHasStopped = false;
			HazeAkComponent.HazePostEvent(StartRotatingEvent);
		}

		HazeAkComponent.SetRTPCValue(HazeAudio::RTPC::HamsterWheelSpeed, CurrentSpeedNormalized, 0);
	}

	UFUNCTION(NetFunction, Unreliable)
	void NetSyncSpeedAndRotation(float Roll, float Speed)
	{
		DesiredRotation = Roll;
		CurrentSpeed = Speed;
	}

    void ClampSpeed()
    {
        if (WheelAngle >= MaxAngle - 1)
        {
            CurrentSpeed = FMath::Clamp(CurrentSpeed, -99, 0);
        }

        else if (WheelAngle < Minangle)
        {
            CurrentSpeed = FMath::Clamp(CurrentSpeed, 0, 99);
        }
    }

    void UpdateMoveDirection(FVector Movedirection)
    {
        float moveAcceleration = Movedirection.DotProduct(ActorTransform.Rotation.RightVector); 
        CurrentSpeed += moveAcceleration * 5;
    }

    UFUNCTION()
	void OnInteracted(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
        Player.SmoothSetLocationAndRotation(Component.WorldLocation, Component.WorldRotation);

        Player.SetCapabilityAttributeObject(n"HamsterWheel", this);
        Player.SetCapabilityAttributeObject(n"Interaction", Component);
        Player.SetCapabilityActionState(n"InHamsterWheel", EHazeActionState::Active);
        Component.Disable(n"Interacted");
        InWheel = true;
		HasBeenInteractedOnce = true;
		CurrentSpeed = 0;
        PlayerInWheel = Player;
		AngleSync.OverrideControlSide(PlayerInWheel);
		SpeedSync.OverrideControlSide(PlayerInWheel);
    }

    void ReleaseWheel(UHazeTriggerComponent Interaction)
    {
        Interaction.Enable(n"Interacted");
        InWheel = false;
        CurrentSpeed=0;
    }
}