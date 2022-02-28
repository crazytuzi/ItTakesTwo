import Peanuts.Audio.AudioStatics;
import Vino.Movement.Components.MovementComponent;
import Vino.Audio.PhysMaterials.PhysicalMaterialAudio;

UCLASS(NotBlueprintable, meta = (DisplayName = "Haze Audio Event"))
class UAnimNotify_HazeAudioEvent : UAnimNotify
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

	UPROPERTY(Meta = (EditCondition = "bAttachToMesh"))
	FName AttachBone = NAME_None;

	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		if (MeshComp.GetOwner() == nullptr)			
			return true;

		auto HazeOwner = Cast<AHazeActor>(MeshComp.Owner);
		AHazePlayerCharacter PlayerOwner = Cast<AHazePlayerCharacter>(HazeOwner);
		if (HazeOwner != nullptr)
		{
			UHazeAkComponent HazeAkComp;

			if(PlayerOwner != nullptr)
			{
				HazeAkComp = UPlayerHazeAkComponent::GetOrCreate(HazeOwner, n"PlayerHazeAkComponent");
			}
			else
			{	
				(HazeAkComponentName == NAME_None ? HazeAkComp = UHazeAkComponent::GetOrCreate(HazeOwner) : HazeAkComp = UHazeAkComponent::Get(HazeOwner, HazeAkComponentName));		

				if(HazeAkComp == nullptr)
					return false;
			}			

			if(OverrideEvent != nullptr)
			{
				if(bAttachToMesh)
				{
					HazeAkComp.AttachTo(MeshComp, AttachBone, EAttachLocation::SnapToTarget);
				}				
				
				HazeAkComp.HazePostEvent(OverrideEvent, "", EHazeAudioPostEventType::Animation_Notify);       
			}
			else
			{
				UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(HazeOwner);
				if(MoveComp != nullptr)
				{
					UAkAudioEvent Event;
					UPhysicalMaterial PhysMat = MoveComp.GetContactSurfaceMaterial();	
					if (PhysMat != nullptr)
					{
						UPhysicalMaterialAudio PhysMatAudio = Cast<UPhysicalMaterialAudio>(PhysMat.AudioAsset);
						if(PhysMatAudio != nullptr && PlayerOwner!= nullptr)
						{						
							Event = PhysMatAudio.GetMaterialByTag(PlayerOwner, Tag).AudioEvent;		

							HazeAkComp.HazePostEvent(Event,"", EHazeAudioPostEventType::Animation_Notify);
						}
					}						
				}
			}
			
			if(bPlayerPanning)
			{
				HazeAudio::SetPlayerPanning(HazeAkComp, HazeOwner);
			}
		}		

		else if(OverrideEvent != nullptr)
		{
			FOnAkPostEventCallback EventCallback = FOnAkPostEventCallback();
			AkGameplay::PostEvent(OverrideEvent, MeshComp.GetOwner(), 0);
		}		

		return false;
	}
}
