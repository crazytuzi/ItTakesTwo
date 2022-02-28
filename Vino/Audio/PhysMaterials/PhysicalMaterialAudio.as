import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimalComponent;

struct FAudioPhysMaterial
{	
	UPROPERTY()
	FName Tag = NAME_None;

	UPROPERTY()
	UAkAudioEvent AudioEvent;
	
	HazeAudio::EMaterialFootstepType MaterialType;		
	HazeAudio::EMaterialSlideType SlideType;
};

struct FMayMaterialEvents
{	
	UPROPERTY()
	UAkAudioEvent MayMaterialFootstepEvent;		
	
	UPROPERTY()
	UAkAudioEvent MayMaterialScuffEvent;

	UPROPERTY()
	UAkAudioEvent MayMaterialHandEvent;		

	UPROPERTY()
	UAkAudioEvent MayMaterialHandScuffEvent;

	UPROPERTY()
	UAkAudioEvent MayMaterialLandEvent;

	UPROPERTY()
	UAkAudioEvent MayMaterialFootSlideEvent;

	UPROPERTY()
	UAkAudioEvent MayMaterialHandSlideEvent;
	
	UPROPERTY()
	UAkAudioEvent MayMaterialAssSlideEvent;

	UPROPERTY()
	UAkAudioEvent MayMaterialGrindMountEvent;	

	UPROPERTY()
	UAkAudioEvent MayMaterialGrindLoopEvent;

	UPROPERTY()
	UAkAudioEvent MayMaterialGrindRetriggerEvent;

	UPROPERTY()
	UAkAudioEvent MayMaterialGrindDismountEvent;

	UPROPERTY()
	UAkAudioEvent MayMaterialGrindStopEvent;

	UPROPERTY()
	UAkAudioEvent MayMaterialGrindPassbyEvent;

	UPROPERTY()
	float MayGrindingPassbyEventApexTime;
}

struct FCodyMaterialEvents
{
	UPROPERTY()
	UAkAudioEvent CodyMaterialFootstepEvent;		
	
	UPROPERTY()
	UAkAudioEvent CodyMaterialScuffEvent;

	UPROPERTY()
	UAkAudioEvent CodyMaterialHandEvent;		

	UPROPERTY()
	UAkAudioEvent CodyMaterialHandScuffEvent;

	UPROPERTY()
	UAkAudioEvent CodyMaterialLandEvent;	

	UPROPERTY()
	UAkAudioEvent CodyMaterialFootSlideEvent;

	UPROPERTY()
	UAkAudioEvent CodyMaterialHandSlideEvent;	

	UPROPERTY()
	UAkAudioEvent CodyMaterialAssSlideEvent;

	UPROPERTY()
	UAkAudioEvent CodyMaterialGrindMountEvent;	

	UPROPERTY()
	UAkAudioEvent CodyMaterialGrindLoopEvent;
	
	UPROPERTY()
	UAkAudioEvent CodyMaterialGrindRetriggerEvent;

	UPROPERTY()
	UAkAudioEvent CodyMaterialGrindDismountEvent;

	UPROPERTY()
	UAkAudioEvent CodyMaterialGrindStopEvent;

	UPROPERTY()
	UAkAudioEvent CodyMaterialGrindPassbyEvent;

	UPROPERTY()
	float CodyGrindingPassbyEventApexTime;
};

namespace PhysicalMaterialAudio
{    
    const FAudioPhysMaterial EmptyMaterial;

	UPhysicalMaterialAudio GetPhysicalMaterialAudioAsset(UPrimitiveComponent Collider, int MaterialIndex = 0)
	{
		if (Collider == nullptr)
			return nullptr;

		UMaterialInterface PrimaryMaterial = Collider.GetMaterial(MaterialIndex);

		if(PrimaryMaterial == nullptr)
			return nullptr;
		
		UPhysicalMaterial Physmat = PrimaryMaterial.GetPhysicalMaterial();

		if(Physmat == nullptr || Physmat.AudioAsset == nullptr)
			return nullptr;

		return Cast<UPhysicalMaterialAudio>(Physmat.AudioAsset);		
	}
};


class UPhysicalMaterialAudio : UPhysicalMaterialAudioAssetBase
{		
	UPROPERTY()
	TArray<FAudioPhysMaterial> MayTaggedEvents;

	UPROPERTY()
	FMayMaterialEvents MayMaterialEvents;	

	UPROPERTY()
	TArray<FAudioPhysMaterial> CodyTaggedEvents;

	UPROPERTY()
	FCodyMaterialEvents CodyMaterialEvents;

	UPROPERTY()
	TArray<FAudioPhysMaterial> ImpactEvents;

	UPROPERTY()
	HazeAudio::EMaterialFootstepType MaterialType;

	UPROPERTY()
	HazeAudio::EMaterialSlideType SlideType;

	FString SwitchGroup = HazeAudio::SWITCH::SurfaceMaterialsSwitchGroup;

	UPROPERTY()
	FString Switch;

	UPROPERTY()
	UNiagaraSystem FootstepEffect;

	UPROPERTY()
	UNiagaraSystem GroundPoundEffect;

	UPROPERTY()
	UNiagaraSystem SlidingTrailEffect;

	UFUNCTION()
	UNiagaraSystem GetGroundPoundEffectEvent()
	{
		return GroundPoundEffect;
	}

	UFUNCTION()
	UNiagaraSystem GetMaterialEffectInteractionEvent(AHazePlayerCharacter Player, HazeAudio::EPlayerFootstepType InteractionType)
	{
		if((InteractionType == HazeAudio::EPlayerFootstepType::Run ||
			InteractionType == HazeAudio::EPlayerFootstepType::Sprint ||
			InteractionType == HazeAudio::EPlayerFootstepType::Crouch) && 
			(FootstepEffect != nullptr))
		{
			return FootstepEffect;
		}
		return nullptr;
	}

	UFUNCTION()
	FAudioPhysMaterial GetMaterialFootstep(AHazePlayerCharacter Player)
	{
		FAudioPhysMaterial FootstepMaterial;

		if(Player.IsMay())
		{
			FootstepMaterial.AudioEvent = MayMaterialEvents.MayMaterialFootstepEvent;
			FootstepMaterial.MaterialType = MaterialType;
			return FootstepMaterial;
		}
		else
		{
			FootstepMaterial.AudioEvent = CodyMaterialEvents.CodyMaterialFootstepEvent;
			FootstepMaterial.MaterialType = MaterialType;
			return FootstepMaterial;
		}
		
	}

	UFUNCTION()
    FAudioPhysMaterial GetMaterialByTag(AHazePlayerCharacter Player, FName ForTag = NAME_None)
    {
        if(Player.IsMay())
		{
			for(FAudioPhysMaterial AudioMat : MayTaggedEvents)
			{
				if(AudioMat.Tag == ForTag)
					return AudioMat;	
			}
		}
		else
		{
			for(FAudioPhysMaterial AudioMat : CodyTaggedEvents)
			{
				if(AudioMat.Tag == ForTag)
					return AudioMat;	
			}
		}

        return PhysicalMaterialAudio::EmptyMaterial;
    }    

	UAkAudioEvent GetImpactEvent(FName ImpactTag) const
	{
		for(FAudioPhysMaterial& AudioPhysMat : ImpactEvents)
		{
			if(AudioPhysMat.Tag == ImpactTag)
				return AudioPhysMat.AudioEvent;
		}

		return nullptr;
	}

	UFUNCTION()
	FAudioPhysMaterial GetMaterialInteractionEvent(AHazePlayerCharacter Player, HazeAudio::EPlayerFootstepType InteractionType)
	{
		FAudioPhysMaterial FootstepMaterial;
		FootstepMaterial.MaterialType = MaterialType;
		FootstepMaterial.SlideType = SlideType;

		if(Player.IsMay())
		{
			switch(InteractionType)
			{
				case HazeAudio::EPlayerFootstepType::Run:
					FootstepMaterial.AudioEvent = MayMaterialEvents.MayMaterialFootstepEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::Crouch:
					FootstepMaterial.AudioEvent = MayMaterialEvents.MayMaterialFootstepEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::Sprint:
					FootstepMaterial.AudioEvent = MayMaterialEvents.MayMaterialFootstepEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::ScuffLowIntensity:
					FootstepMaterial.AudioEvent = MayMaterialEvents.MayMaterialScuffEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::ScuffHighIntensity:
					FootstepMaterial.AudioEvent = MayMaterialEvents.MayMaterialScuffEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::HandScuff:
					FootstepMaterial.AudioEvent = MayMaterialEvents.MayMaterialHandScuffEvent;	
					return FootstepMaterial;							
				case HazeAudio::EPlayerFootstepType::HandsImpactLowIntensity:
					FootstepMaterial.AudioEvent = MayMaterialEvents.MayMaterialHandEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::HandsImpactHighIntensity:
					FootstepMaterial.AudioEvent = MayMaterialEvents.MayMaterialHandEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::LandingLowIntensity:
					FootstepMaterial.AudioEvent = MayMaterialEvents.MayMaterialLandEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::LandingHighIntensity:
					FootstepMaterial.AudioEvent = MayMaterialEvents.MayMaterialLandEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::FootSlide:
					FootstepMaterial.AudioEvent = MayMaterialEvents.MayMaterialFootSlideEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::HandSlide:
					FootstepMaterial.AudioEvent = MayMaterialEvents.MayMaterialHandSlideEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::AssSlide:
					FootstepMaterial.AudioEvent = MayMaterialEvents.MayMaterialAssSlideEvent;
					return FootstepMaterial;
									
				default:
					return FootstepMaterial;				
			}			
		}
		else
		{
			switch(InteractionType)
			{
				case HazeAudio::EPlayerFootstepType::Run:
					FootstepMaterial.AudioEvent = CodyMaterialEvents.CodyMaterialFootstepEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::Crouch:
					FootstepMaterial.AudioEvent = CodyMaterialEvents.CodyMaterialFootstepEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::Sprint:
					FootstepMaterial.AudioEvent = CodyMaterialEvents.CodyMaterialFootstepEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::ScuffLowIntensity:
					FootstepMaterial.AudioEvent = CodyMaterialEvents.CodyMaterialScuffEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::ScuffHighIntensity:
					FootstepMaterial.AudioEvent = CodyMaterialEvents.CodyMaterialScuffEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::HandScuff:
					FootstepMaterial.AudioEvent = CodyMaterialEvents.CodyMaterialHandScuffEvent;
					return FootstepMaterial;												
				case HazeAudio::EPlayerFootstepType::HandsImpactLowIntensity:
					FootstepMaterial.AudioEvent = CodyMaterialEvents.CodyMaterialHandEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::HandsImpactHighIntensity:
					FootstepMaterial.AudioEvent = CodyMaterialEvents.CodyMaterialHandEvent;
					return FootstepMaterial;			
					case HazeAudio::EPlayerFootstepType::LandingLowIntensity:
					FootstepMaterial.AudioEvent = CodyMaterialEvents.CodyMaterialLandEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::LandingHighIntensity:
					FootstepMaterial.AudioEvent = CodyMaterialEvents.CodyMaterialLandEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::FootSlide:
					FootstepMaterial.AudioEvent = CodyMaterialEvents.CodyMaterialFootSlideEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::HandSlide:
					FootstepMaterial.AudioEvent = CodyMaterialEvents.CodyMaterialHandSlideEvent;
					return FootstepMaterial;
				case HazeAudio::EPlayerFootstepType::AssSlide:
					FootstepMaterial.AudioEvent = CodyMaterialEvents.CodyMaterialAssSlideEvent;
					return FootstepMaterial;
				default:
					return FootstepMaterial;
			}
			
		}

		return FootstepMaterial;
	}
	

	UFUNCTION(BlueprintCallable)
	void GetMaterialSwitch(TArray<FString>& SwitchData)
	{
		if(!Switch.IsEmpty())
		{
			SwitchData.Add(SwitchGroup);
			SwitchData.Add(Switch);			
		}
		else
		{
			SwitchData.Add(SwitchGroup);
			SwitchData.Add(HazeAudio::SWITCH::SurfaceMaterialSwitchDefault);			
		}		
	}

	UFUNCTION(BlueprintCallable)
	HazeAudio::EMaterialFootstepType GetMaterialHardness()
	{		
		return MaterialType;
	}
}
