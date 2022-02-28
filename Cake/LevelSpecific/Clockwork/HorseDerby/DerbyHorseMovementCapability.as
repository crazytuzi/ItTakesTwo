import Cake.LevelSpecific.Clockwork.HorseDerby.DerbyHorseActor;
import Cake.LevelSpecific.Clockwork.HorseDerby.HorseDerbyManager;

class UDerbyHorseMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"DerbyHorse");
	default CapabilityTags.Add(n"DerbyHorseMovement");

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 50;

	ADerbyHorseActor HorseActor;
	UHazeSplineFollowComponent SplineFollowComp;
	AHazePlayerCharacter Player;
	UHazeSplineComponent SplineComp;
	AHorseDerbyManager Manager;

	UDerbyHorseComponent HorseComp;

	float MovementSpeed = 0.f;
	float DefaultMovementSpeed = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		HorseActor = Cast<ADerbyHorseActor>(Owner);
		SplineFollowComp = HorseActor.SplineFollowComp;
		Manager = Cast<AHorseDerbyManager>(GetAttributeObject(n"Manager"));
		HorseComp = HorseActor.HorseComponent;

		//this can be null if not set up on instance, control/verify
		SplineComp = HorseActor.SplineTrack.SplineComp;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(HorseActor.InteractingPlayer != nullptr && Manager.Gamestate == EDerbyHorseState::GameActive)
			return EHazeNetworkActivation::ActivateFromControl;
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{	
		if(HorseActor.InteractingPlayer == nullptr || Manager.Gamestate != EDerbyHorseState::GameActive || HorseActor.HorseState == EDerbyHorseState::GameWon)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if(!SplineFollowComp.HasActiveSpline())
			SplineFollowComp.ActivateSplineMovement(SplineComp, true);

		Player = HorseActor.InteractingPlayer;
		MovementSpeed = Manager.GameActiveHorseSpeed;
		DefaultMovementSpeed = MovementSpeed;

		HorseComp.MovementState = EDerbyHorseMovementState::Run;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		MoveTowardsTargetPoint(DeltaTime);
	}

	void MoveTowardsTargetPoint(float DeltaTime)
	{
		FHazeSplineSystemPosition SystemPosition;

		MovementSpeed = DefaultMovementSpeed;
		MovementSpeed *= HorseComp.SpeedMultiplier;

		float EndPointDistance = SplineComp.GetDistanceAlongSplineAtWorldLocation(HorseActor.SplineTrack.GetWorldLocationAtStatePosition(EDerbyHorseState::GameActive));
		float CurrentDistance = SplineComp.GetDistanceAlongSplineAtWorldLocation(SplineFollowComp.Position.WorldLocation);

		float PredictedDistance = CurrentDistance + (MovementSpeed * DeltaTime);

		if(PredictedDistance < EndPointDistance)
		{
			if(SplineFollowComp.HasActiveSpline())
				SplineFollowComp.UpdateSplineMovement(MovementSpeed * DeltaTime, SystemPosition);
			
			HorseActor.SetActorLocation(SplineFollowComp.Position.WorldLocation);
		}
		else
		{
			if(SplineFollowComp.HasActiveSpline())
				SplineFollowComp.UpdateSplineMovement((MovementSpeed / 2.5f) * DeltaTime, SystemPosition);
			
			HorseActor.SetActorLocation(SplineFollowComp.Position.WorldLocation);

			//Move to Target
			// PrintToScreen("Move to Target");

			// if(SplineFollowComp.HasActiveSpline())
			// 	SplineFollowComp.UpdateSplineMovement(HorseActor.SplineTrack.GetWorldLocationAtStatePosition(EDerbyHorseState::GameActive), SystemPosition);

			// HorseActor.SetActorLocation(SplineFollowComp.Position.WorldLocation);
		}
	}
}