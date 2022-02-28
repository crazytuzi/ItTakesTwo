import Cake.LevelSpecific.PlayRoom.GoldBerg.MarbleBall.MarbleBall;
import Cake.LevelSpecific.PlayRoom.GoldBerg.MarbleTags;

class UMarblePositionCorrectorCapability : UHazeCapability
{
	
	default TickGroup = ECapabilityTickGroups::AfterPhysics;
	default TickGroupOrder = 90;

	AMarbleBall Marble;
    UHazeSplineComponent CurrentSpline;
    float SwappedSplineTimer;
    float InterpolationTime = 1.f;

    const float MarbleRadius = 22.5f;
    const float MarbleScale = 1.5f;

	default CapabilityTags.Add(FMarbleTags::MarblePhysics);


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Marble = Cast<AMarbleBall>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (Marble.Spline != nullptr && HasControl())
        {
            return EHazeNetworkActivation::ActivateLocal;
        }
        else
        {
            return EHazeNetworkActivation::DontActivate;
        }
        
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Marble.Spline != nullptr && HasControl())
        {
            return EHazeNetworkDeactivation::DontDeactivate;
        }
        else
        {
            return EHazeNetworkDeactivation::DeactivateLocal;
        }
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
        if (CurrentSpline != Marble.Spline)
        {
            SwappedSplineTimer = InterpolationTime;
        }

        else if (SwappedSplineTimer > 0)
        {
            SwappedSplineTimer -= DeltaTime;
            InterpolateToCorrectPosition();
        }
        
        else
        {
            CorrectPosition();
        }

        CurrentSpline = Marble.Spline;
	}

    void InterpolateToCorrectPosition()
    {
        FVector WorldLocation = Marble.Spline.FindLocationClosestToWorldLocation(TraceDownWards, ESplineCoordinateSpace::World);
        WorldLocation.Z = Marble.ActorLocation.Z;

        WorldLocation = FMath::Lerp(Marble.GetActorLocation(), WorldLocation, InterpolationTime - SwappedSplineTimer);

        FHitResult hitresult;
        Marble.SetActorLocation(WorldLocation, false, hitresult, true);
    }

    void CorrectPosition()
    {
        float SplineDistance = 0;
        FVector WorldLocation = FVector::ZeroVector;
        Marble.Spline.FindDistanceAlongSplineAtWorldLocation(TraceDownWards, WorldLocation, SplineDistance);
        WorldLocation.Z = Marble.ActorLocation.Z;

        FVector TangentAtSplinePoint = Marble.Spline.GetTangentAtDistanceAlongSpline(SplineDistance, ESplineCoordinateSpace::World);

        FHitResult hitresult;
        Marble.SetActorLocation(WorldLocation, false, hitresult, true);
    }

    FVector GetBottomOFMarbleBall() const property
    {
        FVector LocationOffset = FVector::UpVector;
        LocationOffset *= MarbleRadius * MarbleScale;
        return Marble.ActorLocation;
    }

    FVector GetTraceDownWards() const property
    {
        TArray<AActor> ActorsToIgnore;

        ActorsToIgnore.Add(Marble);
        FHitResult Hit;
        if (System::LineTraceSingle(Marble.GetActorLocation(), (Marble.GetActorLocation() + FVector::UpVector * -1000), ETraceTypeQuery::TraceTypeQuery1, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, true))
        {
            return Hit.Location;
        }

        else
        {
            return BottomOFMarbleBall;
        }
    }
}