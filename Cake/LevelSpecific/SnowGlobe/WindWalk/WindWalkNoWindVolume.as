import void AddWindWalkNoWindVolume(AHazePlayerCharacter Player, AWindWalkNoWindVolume WindWalkNoWindVolume) from "Cake.LevelSpecific.SnowGlobe.WindWalk.WindWalkComponent";
import void RemoveWindWalkNoWindVolume(AHazePlayerCharacter Player, AWindWalkNoWindVolume WindWalkNoWindVolume) from "Cake.LevelSpecific.SnowGlobe.WindWalk.WindWalkComponent";

class AWindWalkNoWindVolume : AHazeActor
{
	UPROPERTY()
	bool bRequiresCrouching;

	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent BoxVolume;
	default BoxVolume.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default BoxVolume.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY()
	UHazeCapabilitySheet WindWalkCapabilitySheet;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Add CapabilitySheetRequest
		Capability::AddPlayerCapabilitySheetRequest(WindWalkCapabilitySheet);

/*
		TArray<AActor> Actors;

		BoxVolume.GetOverlappingActors(Actors);

		for (auto Actor : Actors)
		{
			AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
	
			if (Player != nullptr)
			{
				AddWindWalkNoWindVolume(Player, this);
			}
		}
*/
		BoxVolume.OnComponentBeginOverlap.AddUFunction(this, n"BoxVolumeOnBeginOverlap");
		BoxVolume.OnComponentEndOverlap.AddUFunction(this, n"BoxVolumeOnEndOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		// Remove CapabilitySheetRequest
		Capability::RemovePlayerCapabilitySheetRequest(WindWalkCapabilitySheet);
	}

	UFUNCTION()
	void BoxVolumeOnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
		{
			AddWindWalkNoWindVolume(Player, this);
		}
	}

	UFUNCTION()
	void BoxVolumeOnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr)
		{
			RemoveWindWalkNoWindVolume(Player, this);
		}

	}
}