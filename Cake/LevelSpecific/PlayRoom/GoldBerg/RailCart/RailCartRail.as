import Peanuts.Spline.SplineComponent;
import Peanuts.Spline.SplineAutomaticConnectComponent;

// A component required to connect the rails in different levels
UCLASS()
class URailCartRailForcedConnector : USceneComponent
{
	UPROPERTY()
	FName ConnectionName;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TArray<USceneComponent> Parents;
		GetParentComponents(Parents);

		for(int i = 0; i < Parents.Num(); ++i)
		{
			auto FoundConnector = Cast<USplineAutomaticConnectComponent>(Parents[i]);
			if(FoundConnector != nullptr)
			{
				Connector = FoundConnector;
				break;
			}
		}

		devEnsure(Connector != nullptr, "The RailCartRailForcedConnector on " + Owner.GetName() + "has not been placed under a SplineAutomaticConnectComponent");
	}

	void EstablishConnection()
	{
		TArray<AActor> Rails;
		GetAllActorsOfClass(ARailCartRail::StaticClass(), Rails);
		for(int i = 0; i < Rails.Num(); ++i)
		{
			auto OtherConnector = URailCartRailForcedConnector::Get(Rails[i]);
			if(OtherConnector == nullptr)
				continue;

			if(OtherConnector == this)
				continue;

			if(OtherConnector.ConnectionName != ConnectionName)
				continue;
	
			Connector.CreateConnection(OtherConnector.Connector);
			OtherConnector.Connector.CreateConnection(Connector);
			return;
		}

		devEnsure(false, "EstablishConnection on " + Owner.GetName() + "could not find any other matching connector");
	}

	private USplineAutomaticConnectComponent Connector;
}

class ARailCartRail : AHazeActor
{
	default UpdateOverlapsMethodDuringLevelStreaming = EActorUpdateOverlapsMethod::AlwaysUpdate;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	default Root.SetMobility(EComponentMobility::Static);

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;
	default Spline.SetMobility(EComponentMobility::Static);

	UPROPERTY(DefaultComponent, Attach = Spline)
	USceneComponent ConnectorStart;
	default ConnectorStart.SetMobility(EComponentMobility::Static);

	UPROPERTY(DefaultComponent, Attach = ConnectorStart)
	USplineAutomaticConnectComponent ConnectStart;
	default ConnectStart.SetMobility(EComponentMobility::Static);
	default ConnectStart.BoxExtent = FVector(50.f, 50.f, 50.f);

	UPROPERTY(DefaultComponent, Attach = Spline)
	USceneComponent ConnectorEnd;
	default ConnectorEnd.SetMobility(EComponentMobility::Static);

	UPROPERTY(DefaultComponent, Attach = ConnectorEnd)
	USplineAutomaticConnectComponent ConnectEnd;
	default ConnectEnd.SetMobility(EComponentMobility::Static);
	default ConnectEnd.BoxExtent = FVector(50.f, 50.f, 50.f);

	UPROPERTY(Category = "Spline")
	UStaticMesh Mesh;

	UPROPERTY(Category = "Spline")
	float SegmentLength = 100.f;

	UPROPERTY(Category = "Spline")
	bool bAutoTangents = false;

	UPROPERTY(Category = "Spline")
	bool bHasCollision = true;

	UPROPERTY(Category = "Development")
	AActor CopySplineTarget;

	ARailCartRail NextRail;
	ARailCartRail PrevRail;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Spline.AutoTangents = bAutoTangents;

		ConnectEnd.SetCollisionProfileName(ConnectEnd.Mobility == EComponentMobility::Static ? n"OverlapAll" : n"OverlapAllDynamic");
		ConnectStart.SetCollisionProfileName(ConnectStart.Mobility == EComponentMobility::Static ? n"OverlapAll" : n"OverlapAllDynamic");

		/* BUILD DAT SPLINE MESH */
		// Okay,
		// So, first of all we want to always have an integer amount of spline-meshes between every spline-point
		// so that we avoid the situation of a spline-mesh spanning in-between a spline-point, which makes perfectly
		// following the spline harder.
		// So inbetween every point we figure out how many segments we can fit (rounded up right now)
		// Then we just make them! Splitting the spline up into chunks and getting position/tangent/roll at those points.
		const ESplineCoordinateSpace Space = ESplineCoordinateSpace::Local;
		for(int PointIndex = 0; PointIndex<Spline.NumberOfSplinePoints - 1; ++PointIndex)
		{
			float PointDistA = Spline.GetDistanceAlongSplineAtSplinePoint(PointIndex);
			float PointDistB = Spline.GetDistanceAlongSplineAtSplinePoint(PointIndex + 1);

			// Distance of this point to next
			float PointLength = PointDistB - PointDistA;
			uint32 NumSegments = FMath::CeilToInt(PointLength / SegmentLength);
			float SegLength = PointLength / NumSegments;

			// Make the segments!
			for(uint32 SegIndex = 0; SegIndex < NumSegments; ++SegIndex)
			{
				// Start and end of this segment (distance)
				float SegDistA = PointDistA + SegLength * SegIndex;
				float SegDistB = PointDistA + SegLength * (SegIndex + 1);

				FVector SegPosA;
				FVector SegPosB;
				FVector SegTangA;
				FVector SegTangB;
				float SegRollA = 0.f;
				float SegRollB = 0.f;

				/* POSITION */
				SegPosA = Spline.GetLocationAtDistanceAlongSpline(SegDistA, Space);
				SegPosB = Spline.GetLocationAtDistanceAlongSpline(SegDistB, Space);

				/* TANGENT */
				SegTangA = Spline.GetTangentAtDistanceAlongSpline(SegDistA, Space);
				SegTangB = Spline.GetTangentAtDistanceAlongSpline(SegDistB, Space);

				// If this is the last segment, use the arrive tangent of the next point instead
				if (SegIndex == NumSegments - 1)
				{
					SegTangB = Spline.GetArriveTangentAtSplinePoint(PointIndex + 1, Space);
				}

				// IMPORTANT: We HAVE to scale the tangents by the ratio between segment length and point-to-next length (just number of segments).
				// I'm not sure if this always works perfectly.
				SegTangA /= NumSegments;
				SegTangB /= NumSegments;

				/* ROLLING */
				SegRollA = Spline.GetRollAtDistanceAlongSpline(SegDistA, Space);
				SegRollB = Spline.GetRollAtDistanceAlongSpline(SegDistB, Space);

				// Phew! All data in hand, lets create the spline mesh
				auto MeshSpline = Cast<USplineMeshComponent>(CreateComponent(USplineMeshComponent::StaticClass()));
				if (bHasCollision)
				{
					MeshSpline.SetCollisionProfileName(Root.Mobility == EComponentMobility::Static ? n"BlockAll" : n"BlockAllDynamic");
					MeshSpline.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
					MeshSpline.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Block);
				}

				MeshSpline.SetMobility(Root.Mobility);
				MeshSpline.SetStartAndEnd(SegPosA, SegTangA, SegPosB, SegTangB);
				MeshSpline.StaticMesh = Mesh;

				// Roll is in radians for some reason ?????
				MeshSpline.SetStartRoll(SegRollA * DEG_TO_RAD);
				MeshSpline.SetEndRoll(SegRollB * DEG_TO_RAD);
			}
		}

		// Move the connections to end/start of spline
		FTransform StartTransform = Spline.GetTransformAtTime(0.f, Space);
		FTransform EndTransform = Spline.GetTransformAtTime(Spline.Duration, Space);
		ConnectorStart.SetRelativeTransform(StartTransform);
		ConnectorEnd.SetRelativeTransform(EndTransform);

		// Set override distances so that we dont accidentally get the wrong distance along spline in loops
		ConnectStart.AnchorDistanceOverride = 0.f;
		ConnectStart.bOverrideAnchorDistance = true;

		ConnectEnd.AnchorDistanceOverride = Spline.SplineLength;
		ConnectEnd.bOverrideAnchorDistance = true;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
	}

	UFUNCTION(Category = "Development", CallInEditor)
	void CopySpline()
	{
		if (CopySplineTarget == nullptr)
		{
			Print("No copy target", 5.f, FLinearColor::Red);
			return;
		}

		auto CopySpline = UHazeSplineComponent::Get(CopySplineTarget);
		if (CopySpline == nullptr)
		{
			Print("Copy target has no spline component", 5.f, FLinearColor::Red);
			return;
		}

		Spline.ClearSplinePoints(true);
		const ESplineCoordinateSpace Space = ESplineCoordinateSpace::Local;

		for(int i=0; i<CopySpline.NumberOfSplinePoints; ++i)
		{
			FVector Position = CopySpline.GetLocationAtSplinePoint(i, Space);
			FVector ArriveTangent = CopySpline.GetArriveTangentAtSplinePoint(i, Space);
			FVector LeaveTangent = CopySpline.GetLeaveTangentAtSplinePoint(i, Space);
			FRotator Rotation = CopySpline.GetRotationAtSplinePoint(i, Space);
			ESplinePointType Type = CopySpline.GetSplinePointType(i);

			FSplinePoint Point;
			Point.Position = Position;
			Point.ArriveTangent = ArriveTangent;
			Point.LeaveTangent = LeaveTangent;
			Point.Rotation = Rotation;
			Point.Type = Type;
			Point.InputKey = i;

			Spline.AddPoint(Point);
		}

		SetActorTransform(CopySplineTarget.ActorTransform);
	}
}
