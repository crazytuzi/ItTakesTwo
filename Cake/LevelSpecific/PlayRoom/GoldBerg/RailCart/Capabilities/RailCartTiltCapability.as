import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.Names;
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailCart;
import Cake.LevelSpecific.PlayRoom.GoldBerg.RailCart.RailPumpCart;

class URailCartTiltCapability : UHazeCapability
{
	default CapabilityTags.Add(RailCartTags::Cart);
	default CapabilityTags.Add(RailCartTags::Physics);

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	ARailCart Cart;
	ARailPumpCart PumpCart;
	float TiltDistanceOffset = 300.f;

	float TiltAngle = 0.f;
	float Torque = 0.f;

	UHazeAkComponent HazeAkComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Cart = Cast<ARailCart>(Owner);
		PumpCart = Cast<ARailPumpCart>(Owner);
		HazeAkComponent = Cart.HazeAkComponent;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Cart.IsAttachedToSpline())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Cart.IsAttachedToSpline())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeSplineSystemPosition Position = Cart.Position;
		FHazeSplineSystemPosition Position_Next = Position;
		Position_Next.Move(TiltDistanceOffset);

		FHazeSplineSystemPosition Position_Prev = Position;
		Position_Prev.Move(-TiltDistanceOffset);

		FVector Direction_Next = Position_Next.GetWorldForwardVector();
		FVector Direction_Prev = Position_Prev.GetWorldForwardVector();

		// Get how much the tangents are turning around the UpVector
		float TurnRate = Direction_Prev.CrossProduct(Direction_Next).DotProduct(FVector::UpVector);

		float TorqueFactor = 1.f;

		// Find out of horizontal we are, we dont want to tilt if the track is rotated 90 degrees!
		float Horizontalness = Position.GetWorldUpVector().DotProduct(FVector::UpVector);

		// Add torque front turning
		Torque += -TurnRate * Cart.Speed * Horizontalness * (1.f / Cart.Weight) * 1.2f * DeltaTime;

		// Apply gravity to the torque
		Torque -= FMath::Sign(TiltAngle) * 900.f * DeltaTime;

		// If we're currently torque-ing _away_ from the track, limit how much it is applied so that we dont flip over
		if (FMath::Sign(Torque) == FMath::Sign(TiltAngle))
		{
			TorqueFactor = 1.f - Math::Saturate(FMath::Abs(TiltAngle) / 60.f);
			Torque *= TorqueFactor;
		}

		// Apply torque
		float NextAngle = TiltAngle;
		NextAngle += Torque * TorqueFactor * DeltaTime;

		// Did we slam into the track? (TiltAngle flipped sign)
		if (FMath::Sign(TiltAngle) != FMath::Sign(NextAngle))
		{
			float ImpactForce = FMath::Abs(Torque / 300.f);
			if (ImpactForce > 0.08f)
				OnRailImpact(ImpactForce);

			// Reduce torque a lot when slamming into track
			Torque *= 0.6f;

			// If the torque is low enough, just reset everything
			// (This is done to reduce wobbling due to gravity being constantly applied)
			if (FMath::Abs(Torque) < 900.f * DeltaTime)
			{
				NextAngle = 0.f;
				Torque = 0.f;
			}
		}

		TiltAngle = NextAngle;
		
		// Since we're tilting at right/left wheel, but the root is in the middle,
		//	we need to fake two pivots by translating as well as rotating

		// Offset from pivot-to-origin of cart
		FVector Offset = FVector(0.f, 80.f * FMath::Sign(TiltAngle), 0.f);

		// Rotate it around X-axis (simplified since Z will be zero)
		Offset.Z = FMath::Sin(TiltAngle * DEG_TO_RAD) * Offset.Y;
		Offset.Y = FMath::Cos(TiltAngle * DEG_TO_RAD) * Offset.Y;

		// Transform back to pivot-to-offset
		Offset.Y -= 80.f * FMath::Sign(TiltAngle);

		// Apply!
		FRotator Rot;
		Rot.Roll = TiltAngle;
		Cart.TiltRoot.SetRelativeRotation(Rot);
		Cart.TiltRoot.SetRelativeLocation(Offset);

		if(HazeAkComponent != nullptr)
		{
			HazeAkComponent.SetRTPCValue("Rtpc_Vehicles_RailCart_Torque", Math::Saturate(FMath::Abs(Torque) / 500.f), 0);
			HazeAkComponent.SetRTPCValue("Rtpc_Vehicles_RailCart_Tilt", Cart.TiltRoot.WorldRotation.Pitch / 90.0f, 0);
			HazeAkComponent.SetRTPCValue("Rtpc_Vehicles_RailCart_Yaw", Cart.TiltRoot.WorldRotation.Yaw / 360.0f, 0);
			if(PumpCart != nullptr)
				PumpCart.Torque = Math::Saturate(FMath::Abs(Torque));
		}
	}

	void OnRailImpact(float Force)
	{
		// Set force and call audio event
		HazeAkComponent.SetRTPCValue("Rtpc_Vehicles_RailCart_RailImpact_Force", Force, 0);
		if(Cart.RailCollisionEvent != nullptr)
		{
			HazeAkComponent.HazePostEvent(Cart.RailCollisionEvent);
		}
	}
}