import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingVolume;
import Vino.Movement.Capabilities.Swimming.SwimmingSettings;

class USwimmingSurfaceComponent : UActorComponent
{
	FSwimmingSurfaceData SurfaceData;

	
	FSwimmingSurfaceData GetOrCreateSurfaceData(AHazePlayerCharacter Player)
	{
		UHazeMovementComponent MoveComp = UHazeMovementComponent::GetOrCreate(Player);

		// Generate new surface data if the frame number is different
		if (uint(SurfaceData.FrameNumber) != GFrameNumber)
		{
			FVector TraceStartLocation = GetTopTraceLocation(Player, MoveComp);
			FVector TraceEndLocation = GetBottomTraceLocation(Player, MoveComp);
			TArray<FHitResult> Hits;
			TArray<AActor> ActorsToIgnore;
			TArray<EObjectTypeQuery> Objects;
			Objects.Add(EObjectTypeQuery::WorldDynamic);

			System::LineTraceMultiForObjects(TraceStartLocation, TraceEndLocation, Objects, false, ActorsToIgnore, EDrawDebugTrace::None, Hits, false); 

			for (FHitResult Hit : Hits)
			{
				if (Cast<ASnowGlobeSwimmingVolume>(Hit.Actor) != nullptr)
				{
					FSwimmingSurfaceData NewSurfaceData;

					NewSurfaceData.FrameNumber = GFrameNumber;
					NewSurfaceData.WorldLocation = Hit.Location;
					NewSurfaceData.ToSurface = Hit.Location - Player.CapsuleComponent.WorldLocation;
					NewSurfaceData.DistanceToSurface = NewSurfaceData.ToSurface.Size();

					SurfaceData = NewSurfaceData;
					break;
				}
			}
		}

		return SurfaceData;
	}

	FVector GetTopTraceLocation(AHazePlayerCharacter Player, UHazeMovementComponent MoveComp)
	{
		float TraceHeight = FMath::Max(SwimmingSettings::Surface.AcceptanceRangeAboveSurface, SwimmingSettings::Surface.VacuumRange);
		FVector Location = Player.CapsuleComponent.WorldLocation + (MoveComp.WorldUp * TraceHeight);
		return Location;
	}

	FVector GetBottomTraceLocation(AHazePlayerCharacter Player, UHazeMovementComponent MoveComp)
	{
		float TraceDepth = FMath::Max(Player.CapsuleComponent.CapsuleHalfHeight, SwimmingSettings::Surface.AcceptanceRangeBelowSurface);
		FVector Location = Player.CapsuleComponent.WorldLocation - (MoveComp.WorldUp * TraceDepth);
		return Location;
	}
}

struct FSwimmingSurfaceData
{
	int FrameNumber = 0;
	FVector WorldLocation;
	FVector ToSurface;
	float DistanceToSurface = BIG_NUMBER;
}