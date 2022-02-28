import Vino.Pickups.PickupActor;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongInfo;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongTags;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongAbstractUserComponent;
import Cake.Detection.ConeDetectionComponent;
import Cake.LevelSpecific.Music.Singing.SongReactionComponent;
import Cake.LevelSpecific.Music.LevelMechanics.MiniatureAmplifierImpactComponent;

struct FAmplifierImpactNetInfo
{
	UPROPERTY()
	FVector ImpactPoint;
	UPROPERTY()
	UMiniatureAmplifierImpactComponent ImpactComp;
}

UCLASS(Abstract)
class AMiniatureAmplifier : APickupActor
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UPowerfulSongAbstractUserComponent User;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent AntennaMesh;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SpeakerBlastEvent;

	UPROPERTY(DefaultComponent, Attach = Root)
	UConeDetectionComponent ConeDetection;
	default ConeDetection.bTraceVisibility = true;
	default ConeDetection.Range = 1800;

	private TArray<UMiniatureAmplifierImpactComponent> ImpactCollection;
	private TArray<FVector> LocationsToTest;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		ConeDetection.CachedIgnoreActors.Add(this);
		ConeDetection.CachedIgnoreActors.Add(Game::GetCody());
		ConeDetection.CachedIgnoreActors.Add(Game::GetMay());
		AddDebugCapability(n"MiniatureAmplifierDebugCapability");
	}

	UFUNCTION()
	void ShootImpulse()
	{
		if(!HasControl())
			return;

		TArray<FAmplifierImpactNetInfo> Hits;
		GatherImpacts(Hits);

		HazeAkComp.HazePostEvent(SpeakerBlastEvent);

		if(Hits.Num() > 0)
			NetShootImpulse(Hits);
	}

	void GatherImpacts(TArray<FAmplifierImpactNetInfo>& Hits)
	{
		UMiniatureAmplifierContainerComponent Comp = UMiniatureAmplifierContainerComponent::GetOrCreate(Game::GetCody());
		
		for(UMiniatureAmplifierImpactComponent Impact : Comp.ImpactCollection)
		{
			if(!Impact.IsValidImpact())
				continue;

			const float DistToPointSq = Impact.Owner.ActorLocation.DistSquared(ConeDetection.WorldLocation);

			if(DistToPointSq > FMath::Square(ConeDetection.Range))
				continue;

			FVector DirectionTo = (Impact.Owner.ActorLocation - ConeDetection.WorldLocation);
			FVector DirectionToTarget = (Impact.Owner.ActorLocation - ConeDetection.WorldLocation).GetSafeNormal();
			FVector TestLocation = ConeDetection.WorldLocation + ConeDetection.ForwardVector * DirectionTo.Size();

			const float Dot = DirectionToTarget.DotProduct(ConeDetection.ForwardVector);

			if(Dot < 0.0f)
				continue;
			
			UStaticMeshComponent MeshComp = UStaticMeshComponent::Get(Impact.Owner);
			float DistanceToPoint = 0.0f;

			if(MeshComp != nullptr)
			{
				FVector ClosestPoint;
				DistanceToPoint = MeshComp.GetClosestPointOnCollision(ConeDetection.WorldLocation, ClosestPoint);

				if(DistanceToPoint > 0.0f)
				{
					if(ConeDetection.IsPointInsideCone(ClosestPoint, Impact.Owner))
					{
						FAmplifierImpactNetInfo HitInfo;
						HitInfo.ImpactComp = Impact;
						HitInfo.ImpactPoint = ClosestPoint;
						Hits.Add(HitInfo);
						continue;
					}
					else
					{
						FVector Origin, BoxExtent;
						Impact.Owner.GetActorBounds(false, Origin, BoxExtent);
					}
				}
			}

			//if(MeshComp == nullptr || FMath::IsNearlyZero(DistanceToPoint))
			{
				// Let's try the bounding box
				FVector Origin, BoxExtent;
				Impact.Owner.GetActorBounds(false, Origin, BoxExtent);
				LocationsToTest.Reset();
				GatherBoxPoints(LocationsToTest, Origin, BoxExtent);

				for(FVector Location : LocationsToTest)
				{
					if(ConeDetection.IsPointInsideCone(Location, Impact.Owner))
					{
						FAmplifierImpactNetInfo HitInfo;
						HitInfo.ImpactComp = Impact;
						HitInfo.ImpactPoint = Location;
						Hits.Add(HitInfo);
						break;
					}
				}
			}
		}
	}

	void GatherBoxPoints(TArray<FVector>& BoxPoints, FVector Origin, FVector BoxExtent) const
	{
		BoxPoints.Reset();
		const FVector P1 = Origin + FVector(BoxExtent.X, BoxExtent.Y, BoxExtent.Z);
		const FVector P2 = Origin + FVector(-BoxExtent.X, BoxExtent.Y, BoxExtent.Z);
		const FVector P3 = Origin + FVector(-BoxExtent.X, -BoxExtent.Y, BoxExtent.Z);
		const FVector P4 = Origin + FVector(-BoxExtent.X, -BoxExtent.Y, -BoxExtent.Z);
		const FVector P5 = Origin + FVector(BoxExtent.X, BoxExtent.Y, -BoxExtent.Z);
		const FVector P6 = Origin + FVector(BoxExtent.X, -BoxExtent.Y, -BoxExtent.Z);
		const FVector P7 = Origin + FVector(BoxExtent.X, -BoxExtent.Y, BoxExtent.Z);
		const FVector P8 = Origin + FVector(-BoxExtent.X, BoxExtent.Y, -BoxExtent.Z);

		BoxPoints.Add(Origin);
		BoxPoints.Add(P1);
		BoxPoints.Add(P2);
		BoxPoints.Add(P3);
		BoxPoints.Add(P4);
		BoxPoints.Add(P5);
		BoxPoints.Add(P6);
		BoxPoints.Add(P7);
		BoxPoints.Add(P8);
	}

	UFUNCTION(NetFunction)
	private void NetShootImpulse(TArray<FAmplifierImpactNetInfo> ImpactCollection)
	{
		FAmplifierImpactInfo HitInfo;
		HitInfo.Origin = ConeDetection.WorldLocation;
		HitInfo.Instigator = this;
		
		for(FAmplifierImpactNetInfo NetHitInfo : ImpactCollection)
		{
			const FVector DirectionToOrigin = (NetHitInfo.ImpactPoint - HitInfo.Origin).GetSafeNormal();
			HitInfo.DirectionFromInstigator = DirectionToOrigin;
			HitInfo.ImpactPoint = NetHitInfo.ImpactPoint;
			NetHitInfo.ImpactComp.Impact(HitInfo);
		}
	}

	void SortDistance(TArray<FVector>& ListOfPoints) const
	{
		if(ListOfPoints.Num() < 2)
			return;
		
		const FVector Loc = ConeDetection.WorldLocation;

		int SortCount = ListOfPoints.Num();

		while(SortCount > 1)
		{
			for(int Index = 0; Index < (SortCount  - 1); ++Index)
			{
				const FVector LocA = ListOfPoints[Index];
				const FVector LocB = ListOfPoints[Index + 1];

				const float A = Loc.DistSquared(LocA);
				const float B = Loc.DistSquared(LocB);

				if(A > B)
				{
					ListOfPoints.Swap(Index, Index + 1);
				}
			}

			SortCount--;
		}
	}
}