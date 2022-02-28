import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Vino.Trajectory.TrajectoryComponent;
import Vino.Movement.Helpers.BurstForceStatics;

class ASnowGlobeForestSawTree : AHazeActor
{

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent SawRoot;

	UPROPERTY(DefaultComponent)
	USceneComponent TreeRoot;

	UPROPERTY(DefaultComponent, Attach = TreeRoot)
	USceneComponent TreeGhostRoot;

	UPROPERTY(DefaultComponent, Attach = SawRoot)
	UMagnetGenericComponent RedMagnet;
	default RedMagnet.Polarity = EMagnetPolarity::Plus_Red;

	UPROPERTY(DefaultComponent, Attach = SawRoot)
	UMagnetGenericComponent BlueMagnet;
	default BlueMagnet.Polarity = EMagnetPolarity::Minus_Blue;

	FHazeConstrainedPhysicsValue SawPosition;
	default SawPosition.Value = 0.f;
	default SawPosition.LowerBound = -180.f;
	default SawPosition.UpperBound = 180.f;
	default SawPosition.Friction = 12.f;
	default SawPosition.LowerBounciness = 0.f;
	default SawPosition.UpperBounciness = 0.f;

	float SyncingPosition = 0.f;
	float SyncingTimer = 0.f;

	FHazeConstrainedPhysicsValue SawRotation;
	default SawRotation.Value = 0.f;
	default SawRotation.LowerBound = -8.f;
	default SawRotation.UpperBound = 8.f;
	default SawRotation.Friction = 12.f;
	default SawRotation.LowerBounciness = 0.f;
	default SawRotation.UpperBounciness = 0.f;

	FHazeConstrainedPhysicsValue TreeRotation;
	default TreeRotation.Value = 0.f;
	default TreeRotation.LowerBound = 0.f;
	default TreeRotation.UpperBound = 90.f;
	default TreeRotation.Friction = 0.f;
	default TreeRotation.LowerBounciness = 0.35f;
	default TreeRotation.UpperBounciness = 0.35f;

	FTransform SawOrigin;

	float SawTotalDisplacement = 0.f;

	bool bTreeIsCut = false;

	const float SawAcceleration = 9000.f;
	const float SawAngularAcceleration = 600.f;

	// How many units the axe has to cut (back-and-forth) before the tree falls
	UPROPERTY(Category = "Axe")
	float CuttingDisplacementGoal = 6000.f;

	// Size (width) of the saw
	UPROPERTY(Category = "Axe")
	float SawSize = 200.f;

	// Amount of units the axe should cut into the tree before the tree falls
	UPROPERTY(Category = "Axe")
	float SawCutDepth = 200.f;

	// The fall angle the tree should fall (from standing)
	UPROPERTY(Category = "Tree")
	float TreeFallAngle = 90.f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		TreeGhostRoot.SetRelativeRotation(FRotator(-TreeFallAngle, 0.f, 0.f));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TreeRotation.UpperBound = TreeFallAngle;	
		SawOrigin = SawRoot.RelativeTransform;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// Update saw
		float PositionForce = 0.f;
		float RotationForce = 0.f;

		ApplyMagnetForces(RedMagnet, PositionForce, RotationForce);
		ApplyMagnetForces(BlueMagnet, PositionForce, RotationForce);

		SawPosition.AddAcceleration(PositionForce * SawAcceleration);
		SawRotation.AddAcceleration(RotationForce * SawAngularAcceleration);

		SawPosition.Update(DeltaTime);
		SawRotation.Update(DeltaTime);

		// Update network syncing
		// We continuously send over each sides' position to ther other, and both will lerp towards their average position.
		// This way both sides are immediately responsive (as opposed to control-side totally owning the position, which would lag to the slave side)
		if (Network::IsNetworked())
		{
			// Lerp towards syncing position
			SawPosition.Value = FMath::FInterpTo(SawPosition.Value, SyncingPosition, DeltaTime, 0.8f);

			// Sync this sides' position with other side (but only when actually moving the saw)
			if (!FMath::IsNearlyZero(PositionForce))
			{
				SyncingTimer -= DeltaTime;
				if (SyncingTimer < 0.f)
				{
					SyncingTimer = 0.2f;
					NetSendSidePosition(HasControl(), SawPosition.Value);
				}
			}
		}

		// Control side decides when to cut the tree though :)
		SawTotalDisplacement += FMath::Abs(SawPosition.Velocity) * DeltaTime;
		if (SawTotalDisplacement > CuttingDisplacementGoal && HasControl())
		{
			NetCutTree();
		}

		FTransform DepthTranslation(FVector(0.f, -(SawTotalDisplacement / CuttingDisplacementGoal) * SawCutDepth, 0.f));
		FTransform Rotation(FQuat(FVector::UpVector, SawRotation.Value * DEG_TO_RAD));
		FTransform Translation(FVector(SawPosition.Value, 0.f, 0.f));

		SawRoot.SetRelativeTransform(Translation * Rotation * DepthTranslation * SawOrigin);

		// Update the tree
		if (bTreeIsCut)
		{
			float TreeGravForce = (5.f + (1.f * TreeRotation.Value));
			TreeRotation.AddAcceleration(TreeGravForce);
			TreeRotation.Update(DeltaTime);

			if (TreeRotation.HasHitUpperBound())
				OnTreeHitPlanks();
		}

		TreeRoot.SetRelativeRotation(FRotator(-TreeRotation.Value, 0.f, 0.f));
	}

	void ApplyMagnetForces(UMagnetGenericComponent Magnet, float& PositionForce, float& RotationForce) const
	{
		// Adds the magnets accumalitive forces to the input values
		FVector ForceDirection = Magnet.GetDirectionalForceFromAllInfluencers();
		ForceDirection = ForceDirection.ConstrainToPlane(Magnet.UpVector);
		ForceDirection.Normalize();

		PositionForce += ForceDirection.DotProduct(Magnet.ForwardVector);

		// Rotational force is calculated by the relative angle of the pull-direction and the magnets offset
		FVector ToMagnet = Magnet.WorldLocation - ActorLocation;
		ToMagnet.Normalize();
		float Force = ToMagnet.CrossProduct(ForceDirection).DotProduct(ActorUpVector);

		RotationForce += Force;
	}

	UFUNCTION(NetFunction)
	void NetSendSidePosition(bool bControlSide, float Position)
	{
		if (HasControl() == bControlSide)
			return;

		// The syncing position is the average of our current position and the other sides' position
		SyncingPosition = (Position + SawPosition.Value) / 2.f;
	}

	UFUNCTION(NetFunction)
	void NetCutTree()
	{
		bTreeIsCut = true;
		RedMagnet.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		BlueMagnet.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		SawTotalDisplacement = CuttingDisplacementGoal;

		OnTreeStartFalling();
	}

	UFUNCTION(BlueprintPure)
	float GetSawLinearVelocity()
	{
		return SawPosition.Velocity;
	}

	UFUNCTION(BlueprintEvent)
	void OnTreeStartFalling()
	{
	}

	UFUNCTION(BlueprintEvent)
	void OnTreeHitPlanks()
	{
	}

	UFUNCTION(BlueprintCallable)
	void SetTreeHasFallen()
	{
		bTreeIsCut = true;
		RedMagnet.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		BlueMagnet.ChangeValidActivator(EHazeActivationPointActivatorType::None);
		SawTotalDisplacement = CuttingDisplacementGoal;

		TreeRotation.SnapTo(TreeRotation.UpperBound, true);
	}
}