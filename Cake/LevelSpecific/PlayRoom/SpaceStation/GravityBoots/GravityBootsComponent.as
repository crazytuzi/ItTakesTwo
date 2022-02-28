import Vino.Audio.Footsteps.AnimNotify_Footstep;

UCLASS(Abstract)
class UGravityBootsComponent : UActorComponent
{
	UPROPERTY(NotEditable)
	AHazePlayerCharacter Player;

	UPROPERTY()
	USkeletalMesh GravityBootsMesh;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	void GravityBootsActivated()
	{
		Player.BindAnimNotifyDelegate(UAnimNotify_Footstep::StaticClass(), FHazeAnimNotifyDelegate(this, n"Footstep"));
		BP_GravityBootsActivated();
	}

	void GravityBootsDeactivated()
	{
		Player.UnbindAnimNotifyDelegate(UAnimNotify_Footstep::StaticClass(), FHazeAnimNotifyDelegate(this, n"Footstep"));
		BP_GravityBootsDeactivated();
	}

	UFUNCTION(BlueprintEvent)
	void BP_GravityBootsActivated()
	{}

	UFUNCTION(BlueprintEvent)
	void BP_GravityBootsDeactivated()
	{}

	UFUNCTION(NotBlueprintCallable)
	void Footstep(AHazeActor Actor, UHazeSkeletalMeshComponentBase MeshComp, UAnimNotify AnimNotify)
	{
		bool bRightFoot = FMath::RandBool();
		BP_Footstep(bRightFoot);
	}

	UFUNCTION(BlueprintEvent)
	void BP_Footstep(bool bRightFoot)
	{}
}