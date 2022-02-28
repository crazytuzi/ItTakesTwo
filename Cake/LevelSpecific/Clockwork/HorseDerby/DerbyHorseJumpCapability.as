import Cake.LevelSpecific.Clockwork.HorseDerby.DerbyHorseActor;

class UDerbyHorseJumpCapability : UHazeCapability
{
	default CapabilityTags.Add(n"DerbyHorseJump");
	default CapabilityTags.Add(n"DerbyHorse");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	ADerbyHorseActor HorseActor;
	UDerbyHorseComponent HorseComp;
	USceneComponent MovementPoint;
	AHazePlayerCharacter Player;

	FHazeAcceleratedFloat Speed;

	bool JumpFinished = false;
	bool Ascending = false;
	float MinimumJumpHeight = 0.f;
	float StartingHeight;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		HorseActor = Cast<ADerbyHorseActor>(Owner);
		HorseComp = HorseActor.HorseComponent;
		
		MovementPoint = HorseActor.HorseHeightRoot;
		Player = HorseActor.InteractingPlayer;
		StartingHeight = MovementPoint.RelativeLocation.Z;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(IsActioning(n"Jump") && !IsActioning(n"Hit") 
		&& HorseComp.MovementState != EDerbyHorseMovementState::Crouch 
		&& HorseActor.HorseState == EDerbyHorseState::GameActive)
			return EHazeNetworkActivation::ActivateFromControl;
		
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(IsActioning(n"Hit"))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if(JumpFinished)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (HorseActor.HorseDerbyCollideState == EHorseDerbyCollideState::RaceComplete)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		HorseActor.HorseDerbyActorState = EHorseDerbyActorState::Jump;
		Ascending = true;
		JumpFinished = false;
		Speed.SnapTo(0,0);

		HorseComp.MovementState = EDerbyHorseMovementState::Jump;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(HorseActor.HorseState == EDerbyHorseState::Travelling)
			HorseComp.MovementState = EDerbyHorseMovementState::Trot;
		else if(HorseActor.IsAnyCapabilityActive(n"DerbyHorseMovement") && !HorseActor.IsAnyCapabilityActive(n"DerbyHorseHitCapability"))
			HorseComp.MovementState = EDerbyHorseMovementState::Run;
		else if(HorseActor.IsAnyCapabilityActive(n"DerbyHorseHitCapability"))
			HorseComp.MovementState = EDerbyHorseMovementState::Hit;
		else
			HorseComp.MovementState = EDerbyHorseMovementState::Still;
			
		HorseActor.SetCapabilityActionState(n"Jump", EHazeActionState::Inactive);

		HorseActor.HorseDerbyActorState = EHorseDerbyActorState::Default;
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		HandleTranslation(DeltaTime);
	}

	void HandleTranslation(float DeltaTime)
	{
		if(Ascending)
		{
			float Height = MovementPoint.RelativeLocation.Z;

			Speed.AccelerateTo(HorseActor.JumpSpeed, 0.3f, DeltaTime);
	
			float NewHeight = FMath::FInterpConstantTo(Height, HorseActor.JumpHeight, DeltaTime, Speed.Value);

			MovementPoint.SetRelativeLocation(FVector(MovementPoint.RelativeLocation.X, MovementPoint.RelativeLocation.Y, NewHeight));

			if(NewHeight >= HorseActor.JumpHeight)
				Ascending = false;
		}
		else
		{
			Speed.AccelerateTo(-HorseActor.JumpSpeed, 0.5f, DeltaTime);
			float NewHeight = FMath::FInterpConstantTo(MovementPoint.RelativeLocation.Z, StartingHeight, DeltaTime, -Speed.Value);
			MovementPoint.SetRelativeLocation(FVector(MovementPoint.RelativeLocation.X, MovementPoint.RelativeLocation.Y, NewHeight));

			if(MovementPoint.RelativeLocation.Z <= StartingHeight)
			{
				MovementPoint.SetRelativeLocation(FVector(MovementPoint.RelativeLocation.X, MovementPoint.RelativeLocation.Y, StartingHeight));
				JumpFinished = true;
				HorseActor.SetCapabilityActionState(n"Jump", EHazeActionState::Inactive);
			}
		}
	}
}