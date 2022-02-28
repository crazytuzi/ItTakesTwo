import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.Music.LevelMechanics.Nightclub.MusicTunnel.MusicTunnelComponent;

event void FPlayerBeginOverlapArpeggioLine(AHazePlayerCharacter Player);
event void FPlayerEndOverlapArpeggioLine(AHazePlayerCharacter Player);

class AAudioSurfArpeggioLine : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSplineComponent LineSpline;

	UPROPERTY()
	UStaticMesh LineMesh;

	UPROPERTY()
	AHazeActor TunnelSplineActor;

	UPROPERTY()
	float TunnelRadius = 650.f;

	UPROPERTY()
	float OverlapRadius = 200.f;

	UPROPERTY()
	float MeshRollOffset = 0.f;

	UPROPERTY(Category = "Arpeggio line events")
	FPlayerBeginOverlapArpeggioLine OnPlayerBeginOverlap;

	UPROPERTY(Category = "Arpeggio line events")
	FPlayerEndOverlapArpeggioLine OnPlayerEndOverlap;

	UPROPERTY(NotVisible)
	TArray <USplineMeshComponent> SplineMeshes;

	TArray<AHazePlayerCharacter> OverlappingPlayers;

	UPROPERTY(NotVisible)
	FBox PlayerOverlapAABB;

	UPROPERTY()
	UMaterialInstance SplineMeshMaterial;

	private FBox WorldSpacePlayerOverlapAABB;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (TunnelSplineActor == nullptr)
			SetActorTickEnabled(false);

		SetActorTickInterval(0.5f);
		OverlappingPlayers.Empty();

		WorldSpacePlayerOverlapAABB.Min = PlayerOverlapAABB.Min + ActorLocation;
		WorldSpacePlayerOverlapAABB.Max = PlayerOverlapAABB.Max + ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		for (USplineMeshComponent SplineMesh : SplineMeshes)
		{
			if (SplineMesh != nullptr)
				SplineMesh.DestroyComponent(SplineMesh);
		}
		SplineMeshes.Empty(LineSpline.GetNumberOfSplinePoints() - 1);

		UHazeSplineComponent TunnelSpline = (TunnelSplineActor != nullptr) ? UHazeSplineComponent::Get(TunnelSplineActor) : nullptr;
		if (TunnelSpline == nullptr)
		{
			TunnelSplineActor = nullptr;	
			return;
		}

		// Project spline to tunnel wall
		FQuat SplineQuat = LineSpline.ComponentQuat.Inverse();
		TArray<float> LocalTunnelRoll;
		LocalTunnelRoll.SetNum(LineSpline.GetNumberOfSplinePoints());
		for (int i = 0; i < LineSpline.GetNumberOfSplinePoints(); i++)
		{
			FVector SplineLoc = LineSpline.GetLocationAtSplinePoint(i, ESplineCoordinateSpace::World);
			float DistAlongTunnel = TunnelSpline.GetDistanceAlongSplineAtWorldLocation(SplineLoc);
			FVector TunnelCenterLoc = TunnelSpline.GetLocationAtDistanceAlongSpline(DistAlongTunnel, ESplineCoordinateSpace::World);
			FVector ToWallDir = (SplineLoc - TunnelCenterLoc).GetSafeNormal();
			FVector ProjectedLoc = TunnelCenterLoc + ToWallDir * TunnelRadius;
			LineSpline.SetLocationAtSplinePoint(i, ProjectedLoc, ESplineCoordinateSpace::World);
			FVector ProjectedTangent = Math::ConstrainVectorToPlane(LineSpline.GetTangentAtSplinePoint(i, ESplineCoordinateSpace::World), -ToWallDir);
			LineSpline.SetTangentAtSplinePoint(i, ProjectedTangent, ESplineCoordinateSpace::World);
			//LocalTunnelRoll[i] = (SplineQuat * FQuat((ToWallDir).Rotation())).Rotator().Pitch;
			FRotator Rot = FRotator::MakeFromXZ(ProjectedTangent, -ToWallDir);
			LocalTunnelRoll[i] = Rot.Roll;
		}

		// Set up spline meshes following spline
		for (int i = 0; i < LineSpline.GetNumberOfSplinePoints() - 1; i++)
		{
			USplineMeshComponent SplineMesh = USplineMeshComponent::Create(this);
			SplineMesh.AttachTo(LineSpline);
			SplineMesh.SetStaticMesh(LineMesh);
			SplineMesh.LightmapType = ELightmapType::ForceVolumetric;
			SplineMesh.SetCastShadow(false);
			FVector StartLocation = LineSpline.GetLocationAtSplinePoint(i, ESplineCoordinateSpace::Local);
			FVector StartTangent = LineSpline.GetTangentAtSplinePoint(i, ESplineCoordinateSpace::Local);
			FVector EndLocation = LineSpline.GetLocationAtSplinePoint(i + 1, ESplineCoordinateSpace::Local);
			FVector EndTangent = LineSpline.GetTangentAtSplinePoint(i + 1, ESplineCoordinateSpace::Local);
			SplineMesh.SetStartAndEnd(StartLocation, StartTangent, EndLocation, EndTangent, true);
			SplineMesh.SetMaterial(0, SplineMeshMaterial);
			// SplineMesh.SetForwardAxis(ESplineMeshAxis::Z);
			
			SplineMesh.SetStartRoll(FMath::DegreesToRadians(LocalTunnelRoll[i] + MeshRollOffset));
			SplineMesh.SetEndRoll(FMath::DegreesToRadians(LocalTunnelRoll[i + 1] + MeshRollOffset));

			SplineMeshes.Add(SplineMesh);
		}

		// Build collision AABB (quite simple, can be incorrect for loops exteding between spline points, but should be good enough for our purposes)
		if (LineSpline.GetNumberOfSplinePoints() == 0)
		{
			PlayerOverlapAABB = FBox(FVector::ZeroVector, FVector::ZeroVector);
		}
		else
		{
			FVector SplineLoc = LineSpline.GetLocationAtSplinePoint(0, ESplineCoordinateSpace::World) - ActorLocation;
			PlayerOverlapAABB = FBox(SplineLoc, SplineLoc);
			for (int i = 1; i < LineSpline.GetNumberOfSplinePoints(); i++)
			{
				SplineLoc = LineSpline.GetLocationAtSplinePoint(i, ESplineCoordinateSpace::World) - ActorLocation;
				PlayerOverlapAABB += FBox(SplineLoc, SplineLoc);
			}		
			PlayerOverlapAABB.Min -= FVector(OverlapRadius + 10000.f);
			PlayerOverlapAABB.Max += FVector(OverlapRadius + 10000.f);
		}
	}

	bool IsAnyPlayerInAABB()
	{
		const TArray<AHazePlayerCharacter>& Players = Game::GetPlayers();
		for (AHazePlayerCharacter Player : Players)
		{
			if (WorldSpacePlayerOverlapAABB.IsInside(Player.ActorLocation))
				return true;	
		}
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if ((GetActorTickInterval() > 0.f) || (OverlappingPlayers.Num() == 0))
		{
			// Check if we should start/stop passive mode
			if (IsAnyPlayerInAABB())
			{
				SetActorTickInterval(0.f);				
				// System::DrawDebugBox(WorldSpacePlayerOverlapAABB.Center, WorldSpacePlayerOverlapAABB.Extent, FLinearColor::Green, FRotator::ZeroRotator, 0.f, 20.f);
			}
			else
			{
				SetActorTickInterval(0.5f);				
				// System::DrawDebugBox(WorldSpacePlayerOverlapAABB.Center, WorldSpacePlayerOverlapAABB.Extent, FLinearColor::Red, FRotator::ZeroRotator, 0.3f, 10.f);
				return;
			}
		}

		const TArray<AHazePlayerCharacter>& Players = Game::GetPlayers();
		for (AHazePlayerCharacter Player : Players)
		{
			FVector PlayerLoc = Player.ActorLocation;
			FHazeSplineSystemPosition SplinePos = LineSpline.GetPositionClosestToWorldLocation(PlayerLoc, true);
			if ((SplinePos.WorldLocation - PlayerLoc).IsNearlyZero(OverlapRadius))
			{
				// Player is near spline
				if (!OverlappingPlayers.Contains(Player))
				{
					OverlappingPlayers.Add(Player);
					OnPlayerBeginOverlap.Broadcast(Player);
				}
			} 
			else
			{
				// Player is not near spline
				if (OverlappingPlayers.Contains(Player))
				{
					OverlappingPlayers.Remove(Player);
					OnPlayerEndOverlap.Broadcast(Player);
				}
			}
		}
	}
}
