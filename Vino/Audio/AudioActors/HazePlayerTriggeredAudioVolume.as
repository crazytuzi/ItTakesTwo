import Peanuts.Triggers.PlayerTrigger;
import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimalComponent;

enum EAudioVolumeType
{
	None,
	Fern,
	Grass,
	Plant,
}

class UHazePlayerTriggeredAudioVolumeDataAsset : UDataAsset
{
	UPROPERTY()
	UAkAudioEvent MayStartLoopingEvent;
	UPROPERTY()
	UAkAudioEvent MayStopLoopingEvent;
	UPROPERTY()
	UAkAudioEvent MayImpactEvent;

	UPROPERTY()
	UAkAudioEvent CodyStartLoopingEvent;
	UPROPERTY()
	UAkAudioEvent CodyStopLoopingEvent;
	UPROPERTY()
	UAkAudioEvent CodyImpactEvent;

	UPROPERTY()
	UAkAudioEvent SpiderStartLoopingEvent;
	UPROPERTY()
	UAkAudioEvent SpiderStopLoopingEvent;
	UPROPERTY()
	UAkAudioEvent SpiderImpactEvent;


	void GetEvents(bool bIsMay, bool bEntered, bool bIsOnSpider, UAkAudioEvent& EventLoopToPost, UAkAudioEvent& ImpactEvent = nullptr)
	{
		if (!bEntered) 
		{
			if(bIsOnSpider)
			{
				EventLoopToPost = SpiderStopLoopingEvent;
			}
			else
			{
				EventLoopToPost = bIsMay ? 
					MayStopLoopingEvent :
					CodyStopLoopingEvent;
			}
		}
		else 
		{
			if(bIsOnSpider)
			{
				EventLoopToPost = SpiderStartLoopingEvent;
				ImpactEvent = SpiderImpactEvent;
			}
			else
			{
				EventLoopToPost = bIsMay ? 
					MayStartLoopingEvent :
					CodyStartLoopingEvent;

				ImpactEvent = bIsMay ? 
					MayImpactEvent :
					CodyImpactEvent;
			}
		}
	}
}

/**
 * A volume that plays one more more loopings sounds,
 * driven by RTPC's.
 */
class AHazePlayerTriggeredAudioVolume : APlayerTrigger
{
	default bTriggerLocally = true;

    default Shape::SetVolumeBrushColor(this, FLinearColor::Blue);

	UPROPERTY(Category = "Triggered Volume Type")
	UHazePlayerTriggeredAudioVolumeDataAsset AssetData;

	UPROPERTY(Category = "Triggered Volume Type")
	EAudioVolumeType VolumeType;


    void EnterTrigger(AActor Actor) override
	{
		Super::EnterTrigger(Actor);

		PostEvents(Actor, VolumeType, true);
	}

    void LeaveTrigger(AActor Actor) override
	{
		Super::LeaveTrigger(Actor);
		
		PostEvents(Actor, EAudioVolumeType::None, false);
	}

	void PostEvents(AActor Actor, EAudioVolumeType Type, bool bEntered)
	{
		auto Player = Cast<AHazePlayerCharacter>(Actor);
		if (Player == nullptr)
			return;
			
		auto AkComponent = UHazeAkComponent::GetOrCreateHazeAkComponent(Player);

		bool bOnSpider = false;
		// Check if we are mounted on spiders
		UWallWalkingAnimalComponent AnimalComp = UWallWalkingAnimalComponent::Get(Player);
		if(AnimalComp != nullptr && AnimalComp.CurrentAnimal != nullptr)
		{
			AkComponent = AnimalComp.CurrentAnimal.SpiderHazeAkComp;
			bOnSpider = true;
		}

		SetSwitch(Type, AkComponent);

		if (AssetData == nullptr)
			return;

		UAkAudioEvent Loop, Impact;
		AssetData.GetEvents(Player.IsMay(), bEntered, bOnSpider, Loop, Impact);

		AkComponent.HazePostEvent(Loop);
		AkComponent.HazePostEvent(Impact);
	}

	void SetSwitch(EAudioVolumeType Type, UHazeAkComponent PlayerComp)
	{
		FString SwitchType;

		switch (Type)
		{
			case EAudioVolumeType::Fern:
			SwitchType = HazeAudio::SWITCH::PlayerVegetationTypeFern;
			break;
			case EAudioVolumeType::Grass:
			SwitchType = HazeAudio::SWITCH::PlayerVegetationTypeGrass;
			break;
			case EAudioVolumeType::Plant:
			SwitchType = HazeAudio::SWITCH::PlayerVegetationTypePlant;
			break;
			case EAudioVolumeType::None:
			default:
			SwitchType = HazeAudio::SWITCH::PlayerVegetationTypeNone;
			break;
		}

		PlayerComp.SetSwitch(HazeAudio::SWITCH::PlayerVegetationTypeSwitchGroup, SwitchType);
	}
};