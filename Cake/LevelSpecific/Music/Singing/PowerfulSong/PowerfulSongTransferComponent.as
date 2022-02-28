import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongAbstractUserComponent;
import Cake.LevelSpecific.Music.Singing.SongReactionComponent;

class UPowerfulSongTransferComponent : UActorComponent
{
	UPROPERTY()
	AHazeActor TransferActor;

	UPowerfulSongAbstractUserComponent SongUserComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(TransferActor == nullptr)
		{
			return;
		}

		SongUserComponent = UPowerfulSongAbstractUserComponent::GetOrCreate(TransferActor);
		TransferActor.AddCapability(n"PowerfulSongAbstractShootCapability");

		TArray<UActorComponent> SongImpactComponents = Owner.GetComponentsByClass(USongReactionComponent::StaticClass());

		for(UActorComponent Comp : SongImpactComponents)
		{
			USongReactionComponent SongImpact = Cast<USongReactionComponent>(Comp);

			if(SongImpact != nullptr)
			{
				SongImpact.OnPowerfulSongImpact.AddUFunction(this, n"HandleSongImpact");
			}
		}
	}

	UFUNCTION()
	void HandleSongImpact(FPowerfulSongInfo Info)
	{
		SongUserComponent.HandleSongImpact(Info);
	}
}
