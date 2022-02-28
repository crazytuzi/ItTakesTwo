import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.Tomato;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.TomatoTags;
import Cake.Environment.BreakableStatics;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.TomatoDashTargetComponent;

#if EDITOR
const FConsoleVariable CVar_DebugDrawTomatoPhysics("Garden.Tomato.DebugDrawPhysics", 0);
#endif // EDITOR

class UTomatoPhysicsCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 10;

	ATomato Tomato;
	UHazeMovementComponent MoveComp;

	UTomatoSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Tomato = Cast<ATomato>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		Settings = UTomatoSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;
		
		if (!Tomato.bTomatoInitialized)
			return EHazeNetworkActivation::DontActivate;
        
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{		
		if (!Tomato.bTomatoInitialized)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Tomato.Velocity = FVector::ZeroVector;
		Owner.SetCapabilityAttributeVector(TomatoTags::SlideVelocity, FVector::ZeroVector);
		Tomato.AccelerationCurrent = Settings.Acceleration;
		Tomato.MaxSpeedCurrent = Settings.MaxSpeed;
		Tomato.FrictionCurrent = Settings.Friction;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		Tomato.AccelerationCurrent = Settings.Acceleration;//FMath::FInterpTo(Tomato.AccelerationCurrent, Settings.Acceleration, DeltaTime, Settings.AccelerationInterpolationSpeed);
		Tomato.MaxSpeedCurrent = Settings.MaxSpeed;//FMath::FInterpTo(Tomato.MaxSpeedCurrent, Settings.MaxSpeed, DeltaTime, Settings.MaxSpeedInterpolationSpeed);
		Tomato.FrictionCurrent = Settings.Friction;//FMath::FInterpTo(Tomato.FrictionCurrent, Settings.Friction, DeltaTime, 1000.0f);
#if EDITOR
		if(CVar_DebugDrawTomatoPhysics.GetInt() == 1)
		{
			PrintToScreen("Tomato.FrictionCurrent " + Tomato.FrictionCurrent);
			PrintToScreen("Tomato.MaxSpeedCurrent " + Tomato.MaxSpeedCurrent);
			PrintToScreen("Tomato.AccelerationCurrent " + Tomato.AccelerationCurrent);
		}
#endif // EDITOR
		
		const float TomatoScale = Tomato.GetTomatoScale();
		const bool bIsInAir = MoveComp.IsAirborne();
		const float MovementSpeed = (bIsInAir ? Settings.InAirAcceleration : Tomato.AccelerationCurrent) / TomatoScale;

		FVector Velocity = Tomato.Velocity;

		// TODO: Temporary solution for DashCapability
		if(!Tomato.bIsDashing)
		{
			Velocity += (Tomato.CurrentPlayerInput) * MovementSpeed * DeltaTime;
		}
		
		if(!bIsInAir || (bIsInAir && Tomato.bIsDashing))
		{
			float VelSize = Velocity.Size();
			float FrictionScalar = FMath::Clamp(VelSize / Settings.SpeedFrictionModifier, 1.0f, 10.0f);
			float FrictionTarget = FMath::Pow(Tomato.FrictionCurrent, FrictionScalar);
			Velocity *= FMath::Pow(FrictionTarget, DeltaTime);
		}

		FHitResult Hit;
		FVector WallHitNormal;
		if(MoveComp.WallWasHit(WallHitNormal) && !Tomato.bIsDashing)
		{
			UTomatoDashTargetComponent DashTargetComponent = UTomatoDashTargetComponent::Get(MoveComp.ForwardHit.Actor);

			//if (!BreakBreakable(MoveComp.ForwardHit.Actor) && DashTargetComponent != nullptr)
			{
				Tomato.Bounce(WallHitNormal, DashTargetComponent != nullptr ? DashTargetComponent.BounceMultiplier : 1.0f);
				Tomato.PlayWallHitCameraShakeWithCrumb();	// Because this is only running on control
				Tomato.PlayHitWallForceFeedback();
				//PrintToScreen("hiiii there ", 10.0f);
			}
		}
		else if(MoveComp.IsCollidingWithWall(Hit) && !Tomato.bIsDashing && Tomato.BounceList.Num() == 0)
		{
			// If we are pressing movement against the wall
			const FVector DirectionToTarget = (Tomato.GetActorLocation() - Hit.ImpactPoint).GetSafeNormal2D();
			float Mul = 0.0f;
			Mul = FMath::Clamp((Velocity.GetSafeNormal2D().DotProduct(Hit.ImpactNormal) + 1.0f) * (1.0f + FMath::Pow(Mul, 1.1f)), 0.0f, 1.0f);
			Velocity = Velocity * Mul;
		}

		for(FTomatoBounceInfo BounceInfo : Tomato.BounceList)
		{
			
			const float BounceMultiplier = BounceInfo.BounceMultiplier; 
			const FVector FacingDirection2D = Velocity.GetSafeNormal2D();// * -1.0f;
			const FVector ReflectedVector = FMath::GetReflectionVector(FacingDirection2D, BounceInfo.HitNormal);//(WallHitNormal * (2.0f * FacingDirection2D.DotProduct(WallHitNormal))) - FacingDirection2D;
			Velocity = (ReflectedVector * (Velocity.Size() * (Settings.Bounce * BounceMultiplier)) ).ConstrainToPlane(MoveComp.WorldUp);
		}

		Tomato.BounceList.Reset();

		FHitResult HitGround;
		const bool bSkipSlopeVel = true;
		// Still here for reference
		if(!bSkipSlopeVel && MoveComp.LineTraceGround(Tomato.GetActorLocation(), HitGround))
		{
			FVector HitNormal = HitGround.ImpactNormal;
			const float Dot = HitGround.ImpactNormal.DotProduct(FVector::UpVector);

			FVector SlopeVelocity = Tomato.SlopeVelocity;

			float GroundFriction = 1.0f;

			if(HitGround.PhysMaterial != nullptr)
			{
				GroundFriction = HitGround.PhysMaterial.Friction;
			}

			SlopeVelocity.X += (HitNormal.Z * HitNormal.X);
			SlopeVelocity.Y += (HitNormal.Z * HitNormal.Y);

			Velocity += SlopeVelocity * Settings.SlopeSpeed * DeltaTime;
#if EDITOR
			if(CVar_DebugDrawTomatoPhysics.GetInt() == 1)
			{
				System::DrawDebugArrow(Tomato.GetActorLocation(), Tomato.GetActorLocation() + (SlopeVelocity * 400.0f), 5.0f, FLinearColor::Green);
			}
#endif // EDITOR

			SlopeVelocity -= SlopeVelocity * ((Settings.SlopeFriction * Dot) * DeltaTime);

			Tomato.SlopeVelocity = SlopeVelocity;
		}

		if(Velocity.Size2D() > Tomato.MaxSpeedCurrent)
		{
			Velocity = Velocity.GetSafeNormal2D() * Tomato.MaxSpeedCurrent;
		}
		
		if(Velocity.Size() < 0.1f)
		{
			Velocity = FVector::ZeroVector;
		}

		Tomato.Velocity = Velocity;
	}

	bool BreakBreakable(AActor CurActor)
	{
		const FVector Velocity = Tomato.Velocity;
		if (Velocity.Size() < Tomato.MaxSpeedCurrent * 0.8f)
			return false;

		if (CurActor == nullptr)
			return false;

		UBreakableComponent BreakableComp = UBreakableComponent::Get(CurActor);
		if (BreakableComp == nullptr)
			return false;

		FBreakableHitData HitData;
		HitData.DirectionalForce = Velocity.GetSafeNormal() * 1000.f;
		BreakBreakableActor(Cast<AHazeActor>(CurActor), HitData);
		return true;
	}
}
