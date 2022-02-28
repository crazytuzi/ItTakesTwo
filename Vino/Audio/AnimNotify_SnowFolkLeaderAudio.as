import Cake.LevelSpecific.SnowGlobe.SnowFolkCrowd.SnowFolkCrowdMember;
UCLASS(NotBlueprintable, meta = (DisplayName = "SnowFolk Leader Audio"))
class UAnimNotify_SnowFolkLeaderAudio : UAnimNotify
{
	UPROPERTY()
	UAkAudioEvent OverrideEvent;

	UPROPERTY()
	FName HazeAkComponentName = n"";

	UPROPERTY()
	FName Tag;		

	UPROPERTY()
	bool bPlayerPanning = true;

	UPROPERTY()
	bool bAttachToMesh = false;	

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		if (MeshComp.GetOwner() == nullptr)			
			return true;

		ASnowFolkCrowdMember SnowFolkLeader = Cast<ASnowFolkCrowdMember>(MeshComp.GetOwner());
		if(SnowFolkLeader == nullptr)
			return false;

		SnowFolkLeader.PerformAnimationAudioFromLeader(OverrideEvent);
		return true;
	}
}