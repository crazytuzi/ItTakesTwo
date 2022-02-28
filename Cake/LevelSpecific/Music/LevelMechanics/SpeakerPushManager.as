import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Music.Cymbal.CymbalComponent;
import Cake.LevelSpecific.Music.Cymbal.Cymbal;

class ASpeakerPushManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY()
	AActor ActorToJumpTo;

	bool CodyAllowedPush = true;
	bool MayAllowedPush = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		
	}

	UFUNCTION()
	void PushPlayerMay(AHazePlayerCharacter Player)
	{
		if(MayAllowedPush == true)
		{
			FHazeJumpToData JumpData;
			JumpData.AdditionalHeight = 0;
			JumpData.Transform = ActorToJumpTo.GetActorTransform();
			JumpTo::ActivateJumpTo(Player, JumpData);
			MayAllowedPush = false;
			System::SetTimer(this, n"ResetPushBlockMay", 3.f, false);
		}
	}

	UFUNCTION()
	void PushPlayerCody(AHazePlayerCharacter Player)
	{
		if(CodyAllowedPush == true)
		{
			FHazeJumpToData JumpData;
			JumpData.AdditionalHeight = 0;
			JumpData.Transform = ActorToJumpTo.GetActorTransform();
			JumpTo::ActivateJumpTo(Player, JumpData);
			CodyAllowedPush = false;
			System::SetTimer(this, n"ResetPushBlockCody", 3.f, false);
		}
	}
	
	UFUNCTION()
	void ResetPushBlockMay()
	{
		MayAllowedPush = true;
	}	


	UFUNCTION()
	void ResetPushBlockCody()
	{
		CodyAllowedPush = true;
	}

	

}