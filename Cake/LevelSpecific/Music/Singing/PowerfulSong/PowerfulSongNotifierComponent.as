import Cake.LevelSpecific.Music.Singing.SongReactionComponent;

event void FOnPowerfulSongNotify(UPowerfulSongNotifierComponent Instigator);

class UPowerfulSongListenerComponent : UActorComponent
{
	UPROPERTY()
	FOnPowerfulSongNotify OnPowerfulSongNotify;

	void HandlePowerfulSongNotify(UPowerfulSongNotifierComponent Instigator)
	{
		OnPowerfulSongNotify.Broadcast(Instigator);
	}
}

// A class that will send a message to another Actor when a powerful song has hit
class UPowerfulSongNotifierComponent : UActorComponent
{
	UPROPERTY()
	TArray<AHazeActor> ActorsToNotify;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(int Index = ActorsToNotify.Num() - 1; Index >= 0; --Index)
		{
			if(ActorsToNotify[Index] == nullptr)
			{
				ActorsToNotify.RemoveAt(Index);
			}
		}

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
		for(AHazeActor HazeActor : ActorsToNotify)
		{
			UPowerfulSongListenerComponent Listener = UPowerfulSongListenerComponent::Get(HazeActor);

			if(Listener != nullptr)
			{
				Listener.HandlePowerfulSongNotify(this);
			}
		}
	}
}
