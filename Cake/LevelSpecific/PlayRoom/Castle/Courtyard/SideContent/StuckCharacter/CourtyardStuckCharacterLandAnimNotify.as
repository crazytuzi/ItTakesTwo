import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.StuckCharacter.CourtyardStuckCharacter;
class UCourtyardStuckCharacterLandAnimNotify : UAnimNotify
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "StuckCharacterLand";
	}

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		ACourtyardStuckCharacter StuckCharacter = Cast<ACourtyardStuckCharacter>(MeshComp.Owner);		
		if(StuckCharacter == nullptr)
			return false;

		StuckCharacter.Landed();		
		return true;
	}
}