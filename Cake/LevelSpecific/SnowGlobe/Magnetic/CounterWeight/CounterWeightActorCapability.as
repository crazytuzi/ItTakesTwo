
import Cake.LevelSpecific.SnowGlobe.Magnetic.CounterWeight.CounterWeightActor;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;

class UCounterWeightActorCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Magnetic");
	default CapabilityTags.Add(n"CounterWeight");
	UStaticMeshComponent MeshComponent;

	default CapabilityDebugCategory = n"Magnetic";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 150;

	float AccumulatedForce;
	float TimeSinceStarted = 0;
	float DistanceToZeroForce = 500;
	float DistanceLastFrame = 0;

	ACounterWeightActor CounterWeightActor;
	UMagnetGenericComponent CounterWeightComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CounterWeightComp = UMagnetGenericComponent::Get(Owner);
		CounterWeightActor = Cast<ACounterWeightActor>(Owner);
		MeshComponent = CounterWeightActor.Mesh;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		TArray<AHazePlayerCharacter> players;

		if (CounterWeightComp.GetInfluencingPlayers(players) || FMath::Abs(CounterWeightActor.ConstantForce) > 0)
		{
        	return EHazeNetworkActivation::ActivateFromControl;
		}
		else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		TArray<AHazePlayerCharacter> players;

		if (!CounterWeightComp.GetInfluencingPlayers(players) && AccumulatedForce == 0 && FMath::Abs(CounterWeightActor.ConstantForce) == 0)
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}
		else
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(HasControl())
		{
			FVector Force = GetInfluencingForce();
			TimeSinceStarted += DeltaTime;

			if (GetShouldMoveUp(Force))
			{
				AccumulatedForce -= Force.Size() * DeltaTime;
			}
			else
			{
				AccumulatedForce += Force.Size() * DeltaTime;
			}
			
			AccumulatedForce *= FMath::Pow(CounterWeightActor.Friction ,DeltaTime);

			CalcVelocityAndDistance(DeltaTime);
			CheckAndNullForceAtEnds();

			CounterWeightActor.DistanceSync.Value = CounterWeightActor.Progress;
			MoveRoot(DeltaTime);
		}

		else
		{
			CounterWeightActor.Progress = CounterWeightActor.DistanceSync.Value;
			MoveRoot(DeltaTime);
		}
	}

	void CheckAndNullForceAtEnds()
	{
		float DistanceAlongSpline = CounterWeightActor.Spline.GetDistanceAlongSplineAtWorldLocation(MeshComponent.WorldLocation);

		if (DistanceAlongSpline == 0 || (CounterWeightActor.Spline.SplineLength - DistanceAlongSpline) < 10.f)
		{
			AccumulatedForce = 0;
		}
	}

	bool GetShouldMoveUp(FVector Force)
	{	
		float DistanceAlongSpline = CounterWeightActor.Spline.GetDistanceAlongSplineAtWorldLocation(MeshComponent.WorldLocation);
		FVector SplineDirection =  CounterWeightActor.Spline.GetDirectionAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		float DotToForce = Force.GetSafeNormal().DotProduct(SplineDirection.GetSafeNormal());
		return (DotToForce > 0);
	}

	void CalcVelocityAndDistance(float Deltatime)
	{
		float DistanceAlongSpline = CounterWeightActor.Spline.GetDistanceAlongSplineAtWorldLocation(MeshComponent.WorldLocation);
		
		DistanceAlongSpline += AccumulatedForce * Deltatime;

		

		if (CounterWeightActor.bIsAtEnd || FMath::Abs(CounterWeightActor.CounterWeightVelocity) < 0.001f)
		{
			CounterWeightActor.CounterWeightVelocity = 0;
		}
		CounterWeightActor.Progress =  DistanceAlongSpline / CounterWeightActor.Spline.GetSplineLength();
	}

	void MoveRoot(float Deltatime)
	{
		MeshComponent.SetWorldLocation(CounterWeightActor.Spline.GetLocationAtDistanceAlongSpline(CounterWeightActor.Progress * CounterWeightActor.Spline.GetSplineLength() , ESplineCoordinateSpace::World));
		CounterWeightActor.CounterWeightVelocity = ((CounterWeightActor.Progress * CounterWeightActor.Spline.GetSplineLength() - DistanceLastFrame) / Deltatime) * -1 * (1 /3.14f);

		DistanceLastFrame = CounterWeightActor.Progress * CounterWeightActor.Spline.GetSplineLength();
	}

	FVector GetConstantForce() const
	{
		float DistanceAlongSpline = CounterWeightActor.Spline.GetDistanceAlongSplineAtWorldLocation(MeshComponent.WorldLocation);
		float Force = CounterWeightActor.ConstantForce;
		FVector SplineDirection =  CounterWeightActor.Spline.GetDirectionAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);

		return SplineDirection * Force;
	}

	FVector GetInfluencingForce() const
	{
		FVector Totalforce = GetConstantForce();
		TArray<FMagnetInfluencer> Influencers;
		CounterWeightComp.GetInfluencers(Influencers);
		for (const FMagnetInfluencer influencer : Influencers)
		{
			float DistanceToObject = influencer.Influencer.ActorLocation.Distance(MeshComponent.WorldLocation);
			float DistanceForceMultiplier = 1;

			DistanceForceMultiplier = DistanceToObject / DistanceToZeroForce;
			DistanceForceMultiplier = FMath::Clamp(DistanceForceMultiplier ,0, 1);

			if(CounterWeightComp.HasOppositePolarity(UMagneticComponent::Get(influencer.Influencer)))
			{
				Totalforce += (MeshComponent.WorldLocation - influencer.Influencer.ActorLocation).GetSafeNormal() * CounterWeightActor.PlayerInfluencingForce * DistanceForceMultiplier;
				
			}
			else
			{
				Totalforce += (influencer.Influencer.ActorLocation - MeshComponent.WorldLocation).GetSafeNormal() * CounterWeightActor.PlayerInfluencingForce;
			}
		}

		float DistanceAlongSpline = CounterWeightActor.Spline.GetDistanceAlongSplineAtWorldLocation(MeshComponent.WorldLocation);
		FVector SplineDirection =  CounterWeightActor.Spline.GetDirectionAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World);
		float TotalForceDot = (SplineDirection).DotProduct(Totalforce);

		SplineDirection *= TotalForceDot;

		return SplineDirection;
	}
}