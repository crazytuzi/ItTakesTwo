import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.Names;
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailPumpCart;

class URailPumpCartMoveCapability : UHazeCapability
{
	default CapabilityTags.Add(RailCartTags::Cart);
	default CapabilityTags.Add(RailCartTags::Movement);

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 60;

	ARailPumpCart PumpCart;
	UHazeAkComponent HazeAkComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PumpCart = Cast<ARailPumpCart>(Owner);
		HazeAkComp = UHazeAkComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!PumpCart.AreBothPlayersOnCart())
			return EHazeNetworkActivation::DontActivate;

		if (!PumpCart.IsAttachedToSpline())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!PumpCart.AreBothPlayersOnCart())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!PumpCart.IsAttachedToSpline())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		PumpCart.HazeAkComponent.HazePostEvent(PumpCart.StartEvent);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		PumpCart.HazeAkComponent.HazePostEvent(PumpCart.StopEvent);
		PumpCart.Speed = 0.f;
		PumpCart.bBoosting = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float NormalizedCartSpeed = FMath::Abs(PumpCart.Speed) / PumpCart.MaxSpeed;
		HazeAkComp.SetRTPCValue("Rtpc_Vehicles_RailCart_Velocity", Math::Saturate(NormalizedCartSpeed), 0);

		FHazeSplineSystemPosition FramePosition;

		if (HasControl())
		{
			float MoveDelta = PumpCart.Speed * DeltaTime;
			EHazeUpdateSplineStatusType Result = PumpCart.SplineFollow.UpdateSplineMovement(MoveDelta, FramePosition);

			// Bounce against ends!
			if (Result == EHazeUpdateSplineStatusType::AtEnd)
			{
				PumpCart.Speed *= -0.7f;
			}

			PumpCart.CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ReplicationParams;
			PumpCart.CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ReplicationParams);	
			PumpCart.SplineFollow.UpdateReplicatedSplineMovement(ReplicationParams);
			FramePosition = PumpCart.SplineFollow.GetPosition();
		}

		// Update actor position
		FTransform SplineTransform = FramePosition.GetWorldTransform();
		PumpCart.SetActorTransform(SplineTransform);

		// Cache position for visual updates
		PumpCart.Position = FramePosition;
	}
}