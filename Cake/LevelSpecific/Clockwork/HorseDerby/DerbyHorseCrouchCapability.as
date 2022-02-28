import Cake.LevelSpecific.Clockwork.HorseDerby.DerbyHorseActor;

class UDerbyHorseCrouchCapability : UHazeCapability
{
	default CapabilityTags.Add(n"DerbyHorseCrouch");
	default CapabilityTags.Add(n"DerbyHorse");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	ADerbyHorseActor HorseActor;
	UDerbyHorseComponent HorseComp;
	USceneComponent MovementPoint;

	bool CrouchFinished = false;
	bool Descending = false;
	bool CrouchCancelled = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		HorseActor = Cast<ADerbyHorseActor>(Owner);
		HorseComp = HorseActor.HorseComponent;
		
		if(HorseActor != nullptr)
		{
			MovementPoint = HorseActor.HorseHeightRoot;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(IsActioning(n"Crouch") && !IsActioning(n"Hit") 
		&& HorseComp.MovementState != EDerbyHorseMovementState::Jump 
		&& HorseActor.HorseState == EDerbyHorseState::GameActive
		)
			return EHazeNetworkActivation::ActivateFromControl;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(n"Crouch") || HorseActor.HorseState == EDerbyHorseState::GameWon)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (IsActioning(n"Hit"))
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		if (HorseActor.HorseDerbyCollideState == EHorseDerbyCollideState::RaceComplete)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CrouchFinished = false;
		CrouchCancelled = false;
		HorseActor.HorseDerbyActorState = EHorseDerbyActorState::Crouch;
		HorseComp.MovementState = EDerbyHorseMovementState::Crouch;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		HorseActor.SetCapabilityActionState(n"Crouch", EHazeActionState::Inactive);

		HorseComp.MovementState = EDerbyHorseMovementState::Run;

		HorseActor.HorseDerbyActorState = EHorseDerbyActorState::Default;
		
		if(HorseActor.HorseState == EDerbyHorseState::Travelling)
			HorseComp.MovementState = EDerbyHorseMovementState::Trot;
		else if (IsActioning(n"Hit"))
			HorseComp.MovementState = EDerbyHorseMovementState::Hit;
		else if(HorseActor.IsAnyCapabilityActive(n"DerbyHorseMovement"))
			HorseComp.MovementState = EDerbyHorseMovementState::Run;
		else
			HorseComp.MovementState = EDerbyHorseMovementState::Still;
	}

	//NOTE - Height is restored in HorseActor if movement state is not Crouch or Jump
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float NewHeight = FMath::FInterpConstantTo(MovementPoint.RelativeLocation.Z, 70.f, DeltaTime, HorseActor.CrouchSpeed);
		MovementPoint.SetRelativeLocation(FVector(MovementPoint.RelativeLocation.X, MovementPoint.RelativeLocation.Y, NewHeight));
	}
}