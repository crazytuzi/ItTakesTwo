import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongImpactComponent;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongAbstractUserComponent;

void PowerfulSong_GatherImpacts(UPowerfulSongAbstractUserComponent SongUserComponent, FPowerfulSongHitInfo& OutHits)
{
	const FVector ForwardVector = SongUserComponent.GetPowerfulSongForward();
	const FVector StartLocation = SongUserComponent.GetPowerfulSongStartLocation();
	OutHits.ProjectileStartLocation = StartLocation;
	OutHits.ProjectileForwardDirection = ForwardVector;
	
	TArray<EObjectTypeQuery> ObjectTypes;
	ObjectTypes.Add(EObjectTypeQuery::WorldDynamic);
	ObjectTypes.Add(EObjectTypeQuery::PlayerCharacter);
	FHazeTraceParams Params;
	Params.InitWithObjectTypes(ObjectTypes);
	Params.OverlapLocation = SongUserComponent.PowerfulSongStartLocation;
	Params.IgnoreActor(SongUserComponent.Owner);
	Params.TraceShape = FCollisionShape::MakeSphere(SongUserComponent.PowerfulSongRange);
	TArray<FOverlapResult> OutOverlaps;
	Params.Overlap(OutOverlaps);
	const FVector RightNormal = SongUserComponent.GetRightNormal();
	const FVector LeftNormal = -SongUserComponent.GetLeftNormal();
	const FVector UpNormal = SongUserComponent.GetUpNormal();
	const FVector BottomNormal = -SongUserComponent.GetBottomNormal();
	for(const FOverlapResult& Overlap : OutOverlaps)
	{
		if(Overlap.Actor == nullptr)
		{
			continue;
		}
		UDEPRECATED_PowerfulSongImpactComponent ImpactComponent = UDEPRECATED_PowerfulSongImpactComponent::Get(Overlap.Actor);
		if(ImpactComponent == nullptr)
		{
			continue;
		}
		const float DistanceToTarget = Overlap.Actor.ActorLocation.Distance(StartLocation);
		const float DistanceToTargetSq = Overlap.Actor.ActorLocation.DistSquared(StartLocation);
		// We do this additional free test because the ActivationPoints, used for the player, uses squared distance check and we need to do the same to get the same result.
		if(DistanceToTargetSq > (SongUserComponent.GetPowerfulSongRange() * SongUserComponent.GetPowerfulSongRange()))
		{
			continue;
		}
		FVector ClosestPoint;
		if(!SongUserComponent.FindClosestPoint(ClosestPoint, ImpactComponent))
		{
			continue;
		}
		if(SongUserComponent.IsPointInsideCone(ClosestPoint, RightNormal, LeftNormal, UpNormal, BottomNormal))
		{
			if(ImpactComponent.bAbsorbPowerfulSong)
			{
				OutHits.Impacts.Empty();
				FPowerfulSongImpactLocationInfo ImpactLocationInfo;
				ImpactLocationInfo.ImpactComponent = ImpactComponent;
				ImpactLocationInfo.ImpactLocation = ClosestPoint;
				OutHits.Impacts.Add(ImpactLocationInfo);
				break;
			}
			else
			{
				FPowerfulSongImpactLocationInfo ImpactLocationInfo;
				ImpactLocationInfo.ImpactComponent = ImpactComponent;
				ImpactLocationInfo.ImpactLocation = ClosestPoint;
				OutHits.Impacts.Add(ImpactLocationInfo);
			}
		}
	}
}
