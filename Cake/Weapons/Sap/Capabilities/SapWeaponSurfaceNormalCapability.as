import Cake.Weapons.Sap.SapWeaponWielderComponent;

struct FSapSurfaceSample
{
	bool bIsValid = false;
	FVector RelativeLocation;
}

class USapWeaponSurfaceNormalCapability : UHazeCapability 
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Weapon);
	default CapabilityTags.Add(ActionNames::WeaponAim);
	default CapabilityTags.Add(SapWeaponTags::Weapon);
	default CapabilityTags.Add(SapWeaponTags::Aim);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::LastDemotable;
	default TickGroupOrder = 105;

	AHazePlayerCharacter Player;
	USapWeaponWielderComponent Wielder;

	const int NumSamples = 12;

	TArray<FVector2D> SurfaceOffsets;
	TArray<FSapSurfaceSample> SurfaceSamples;

	int SampleIndex = 0;
	float TracePullback = 150.f;
	float TraceDistance = 300.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Wielder = USapWeaponWielderComponent::GetOrCreate(Player);

		for(int i=0; i<NumSamples; ++i)
		{
			float Angle = (TAU / NumSamples) * i;
			SurfaceOffsets.Add(FVector2D(FMath::Cos(Angle), FMath::Sin(Angle)) * 50.f);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Wielder.Weapon == nullptr)
	        return EHazeNetworkActivation::DontActivate;

		if (!Wielder.bIsAiming)
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Wielder.Weapon == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!Wielder.bIsAiming)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SurfaceSamples.Empty();
		SurfaceSamples.SetNum(NumSamples);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FSapAttachTarget AimTarget = Wielder.AimTarget;
		if (IsDebugActive())
		{
			System::DrawDebugPoint(AimTarget.WorldLocation, 4.f, FLinearColor::Red);
			System::DrawDebugLine(AimTarget.WorldLocation, AimTarget.WorldLocation + AimTarget.WorldNormal * 50.f, FLinearColor::Red);
		}

		SurfaceSamples[SampleIndex] = SurfaceTrace(SurfaceOffsets[SampleIndex]);
		FTransform ViewTransform = Player.PlayerViewTransform;

		TArray<FVector> SamplePositions;
		SamplePositions.Reserve(NumSamples);
		SamplePositions.Add(AimTarget.WorldLocation);

		for(auto Sample : SurfaceSamples)
		{
			if (!Sample.bIsValid)
				continue;

			FVector WorldLocation = AimTarget.WorldLocation + Sample.RelativeLocation;
			SamplePositions.Add(WorldLocation);
			if (IsDebugActive())
				System::DrawDebugPoint(WorldLocation, 4.f, FLinearColor::Red);
		}

		SampleIndex = (SampleIndex + 1) % NumSamples;

		FVector PlaneNormal;
		if (SamplePositions.Num() == 0 || !FindPlaneOfBestFit(SamplePositions, -ViewTransform.Rotation.ForwardVector, PlaneNormal))
			Wielder.AimSurfaceNormal = -ViewTransform.Rotation.ForwardVector;
		else
			Wielder.AimSurfaceNormal = PlaneNormal;
	}

	FSapSurfaceSample SurfaceTrace(FVector2D Offset)
	{
		FSapAttachTarget AimTarget = Wielder.AimTarget;
		FTransform ViewTransform = Player.PlayerViewTransform;

		// We want to trace longer the steeper the surface is compared to the camera
		float SurfaceCameraDot = AimTarget.WorldNormal.DotProduct(ViewTransform.Rotation.ForwardVector);
		if (FMath::IsNearlyZero(SurfaceCameraDot))
			return FSapSurfaceSample();

		float DistanceMultiplier = 1.f / FMath::Abs(SurfaceCameraDot);

		FVector Start = AimTarget.WorldLocation;
		Start += ViewTransform.Rotation.RightVector * Offset.X;
		Start += ViewTransform.Rotation.UpVector * Offset.Y;
		Start -= ViewTransform.Rotation.ForwardVector * TracePullback * DistanceMultiplier;

		FHazeTraceParams Trace;
		Trace.InitWithTraceChannel(ETraceTypeQuery::Visibility);
		Trace.From = Start;
		Trace.To = Start + ViewTransform.Rotation.ForwardVector * TraceDistance * DistanceMultiplier;
		if (IsDebugActive())
			Trace.DebugDrawTime = 0.f;

		FHazeHitResult Result;
		Trace.Trace(Result);

		if (!Result.bBlockingHit)
			return FSapSurfaceSample();

		FSapSurfaceSample Sample;
		Sample.bIsValid = true;
		Sample.RelativeLocation = Result.ImpactPoint - AimTarget.WorldLocation;
		return Sample;
	}

	// Finds the best fitting plane containing a list of points
	// The alignvector is some prefered directionality of the normal, probably towards the camera
	bool FindPlaneOfBestFit(TArray<FVector> Points, FVector AlignVector, FVector& PlaneNormal)
	{
		// At least 3 points are needed for the points to not be co-linear
		if (Points.Num() < 3)
			return false;

		// Find the centroid of the bunch!
		FVector PointSum;
		for(auto Point : Points)
		{
			PointSum += Point;
		}
		const FVector Centroid = PointSum / Points.Num();

		// Check from the centroid to each pair of 2 points, and get the cross between those two lines
		// Sum all the crosses and then normalize, getting the average normal out of it
		FVector NormalSum;
		for(int i=1; i<Points.Num(); ++i)
		{
			FVector A = Points[i - 1] - Centroid;
			FVector B = Points[i] - Centroid;
			A.Normalize();
			B.Normalize();

			if (B.IsNearlyZero() || A.IsNearlyZero())
				continue;

			// Align the normal towards some base-vector, so that clock-wise and counter-clock-wise cross products
			//	wont ruin the average
			FVector Normal = A.CrossProduct(B);
			Normal = Normal * FMath::Sign(Normal.DotProduct(AlignVector));

			NormalSum += Normal;
		}

		// The points may be too co-linear and the sum will fail
		if (NormalSum.IsNearlyZero())
			return false;

		PlaneNormal = NormalSum.GetSafeNormal();
		return true;
	}
}