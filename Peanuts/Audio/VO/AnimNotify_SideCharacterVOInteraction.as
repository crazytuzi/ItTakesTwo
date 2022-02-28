import Peanuts.Audio.VO.PatrolActorAudioComponent;
import Peanuts.Audio.VO.PatrolActorAudioManagerComponent;

UCLASS(NotBlueprintable, meta = (DisplayName = "Side Character VO Interaction"))
class UAnimNotify_SideCharacterVOInteraction : UAnimNotify
{
	UPROPERTY()
	FName InteractionTag;
	
	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		UPatrolActorAudioComponent PatrolComp = UPatrolActorAudioComponent::Get(MeshComp.GetOwner());
		if(PatrolComp == nullptr)
			return false;	

		auto PatrolManager = GetPatrolAudioManager();
	
		FPatrolAudioEvents PatrolAudioEvents;
		if(PatrolComp.OverridePatrolEvents.IsEmptyPatrolData())
			PatrolManager.GetComponentVODatas(PatrolComp, PatrolAudioEvents);		
		else
			PatrolAudioEvents = PatrolComp.OverridePatrolEvents;
			
		UAkAudioEvent AnimationEvent;
		for(auto& InteractionData : PatrolAudioEvents.AnimationInteractions)
		{
			if(InteractionData.AnimationTag != InteractionTag)
				continue;

			AnimationEvent = InteractionData.AnimationEvent;
			break;
		}			

		PatrolComp.PatrolActorHazeAkComp.HazePostEvent(AnimationEvent);
		return AnimationEvent != nullptr;
	}
}