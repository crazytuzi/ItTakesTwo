import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Rice.Math.MathStatics;
import Peanuts.Audio.AudioStatics;
import Vino.Movement.PlaneLock.PlaneLockStatics;

class ASlidingIceBlock : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	//UCapsuleComponent Collision;
	USphereComponent SphereCollision;
	
	UPROPERTY(DefaultComponent, Attach = Collision)
	UMagnetGenericComponent MagneticComponent;

	UPROPERTY(DefaultComponent)
	UHazeMovementComponent MoveComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent Disable;
	default Disable.bAutoDisable = true;
	default Disable.AutoDisableRange = 10000.f;
	default Disable.bRenderWhileDisabled = true;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ImpactEvent;

	UPROPERTY()
	float Drag = 1.f;

	UPROPERTY()
	float Restitution = 0.25f;

	UPROPERTY()
	float SyncSpeed = 0.5f;

	UPROPERTY()
	bool bAllowRotation;

	UPROPERTY()
	float PullOutDistance = 700.f;

	float SyncRate = 5.f;
	float SyncTimer = 0.f;

	FVector IceBlockVelocity;
	float RotationVelocity = 0.f;

	FVector OtherSideLocation;
	FVector OtherSideDifference;

	FVector StartLocation;

	private bool bLastHitBlocking;
	float ImpactCoolDownTimer = 0.f;
	const float IMPACT_COOLDOWN = 0.25f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveComp.Setup();

		// This be bugged using the default remote collision solver, so we use the control-side solver for both sides
		MoveComp.UseCollisionSolver(MoveComp.ControlSideDefaultCollisionSolver, MoveComp.ControlSideDefaultCollisionSolver);

		FPlaneConstraintSettings Settings;
		Settings.Normal = FVector::UpVector;
		Settings.Origin = ActorLocation;

		StartPlaneLockMovement(this, Settings);

		OtherSideLocation = GetActorLocation();

		StartLocation = GetActorLocation();

		HazeAkComp.HazePostEvent(StartEvent);
		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!MoveComp.CanCalculateMovement())
			return;

		if (Network::IsNetworked())
		{
			SyncTimer += DeltaTime;

			if (SyncTimer > 1.f / SyncRate)
			{
				NetSetOtherSideLocation(HasControl(), GetActorLocation());

				SyncTimer = 0.f;
			}
			
			OtherSideDifference = OtherSideLocation - GetActorLocation();
		}
	
		FVector Force;
		FVector MagnetForce;

		MagnetForce = MagneticComponent.GetDirectionalForceFromAllInfluencers() * 1000.f;

		IceBlockVelocity = MoveComp.GetVelocity();

		Force = MagnetForce + IceBlockVelocity * Drag * -1;

		if (MoveComp.ForwardHit.bBlockingHit)
		{
			//Print("Blocked!" + MoveComp.ForwardHit.Actor.Name);

			if(ImpactCoolDownTimer >= IMPACT_COOLDOWN && !bLastHitBlocking)
			{
				ImpactCoolDownTimer = 0.f;
				HazeAkComp.HazePostEvent(ImpactEvent);
			}
		}

		bLastHitBlocking = MoveComp.ForwardHit.bBlockingHit;

		if(ImpactCoolDownTimer < IMPACT_COOLDOWN)
			ImpactCoolDownTimer += DeltaTime;

		float NormVelo = HazeAudio::NormalizeRTPC01(IceBlockVelocity.Size(), 10.f, 500.f);

		//PrintToScreen("NormVelo: " + NormVelo);

		HazeAkComp.SetRTPCValue("Rtpc_World_Shared_Move_Large_Object_Velocity", NormVelo, 0.f);

		Force = Force.ConstrainToPlane(FVector::UpVector);

		IceBlockVelocity += Force * DeltaTime;

		// Check if we are allowed to rotate
		bAllowRotation = (GetActorLocation() - StartLocation).Size() > PullOutDistance;

		if (!MagnetForce.IsNearlyZero())
		{
			float AngleDifference =	GetAngleBetweenVectorsAroundAxis(GetActorForwardVector(), MagnetForce, GetActorUpVector());

			RotationVelocity += AngleDifference * 2.f * DeltaTime;
		}

		RotationVelocity += RotationVelocity * -1.f * DeltaTime;

		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"Movement");

		FrameMove.OverrideStepDownHeight(0.f);
		FrameMove.OverrideStepUpHeight(0.f);
		FrameMove.ApplyVelocity(IceBlockVelocity);
		FrameMove.ApplyDeltaWithCustomVelocity(OtherSideDifference * SyncSpeed * DeltaTime, FVector::ZeroVector);
		FrameMove.ApplyGravityAcceleration();

		FRotator CurrentRotation = GetActorRotation() + FRotator(0, RotationVelocity * DeltaTime, 0);

		if (bAllowRotation)
			FrameMove.SetRotation(CurrentRotation.Quaternion());

		MoveComp.Move(FrameMove);

		MoveComp.Velocity = IceBlockVelocity;

	}

	UFUNCTION(NetFunction)
	void NetSetOtherSideLocation(bool bControlSide, FVector Location)
	{
		if (HasControl() != bControlSide)
		{
			OtherSideLocation = Location;
		}
	}
}