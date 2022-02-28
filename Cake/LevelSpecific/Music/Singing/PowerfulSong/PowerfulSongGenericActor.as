import Cake.LevelSpecific.Music.Singing.SongReactionComponent;
import Peanuts.Aiming.AutoAimTarget;

event void FOnPowerfulSongImpactBroadcast();
event void FOnSongOfLifeStarted();
event void FOnSongOfLifeEnded();

class APowerfulSongGenericActor: AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USongReactionComponent SongReaction;

	UPROPERTY(DefaultComponent, Attach = SongReaction)
	UAutoAimTargetComponent AutoAimComp;

	UPROPERTY(DefaultComponent, Attach = SongReaction)
	USphereComponent SphereCollision;
	default SphereCollision.bGenerateOverlapEvents = false;
	default SphereCollision.CollisionProfileName = n"WeaponTraceBlocker";
	default SphereCollision.CanCharacterStepUpOn = ECanBeCharacterBase::ECB_No;
	default SphereCollision.SphereRadius = 256.0f;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent Mesh;
	default Mesh.CollisionProfileName = n"NoCollision";
	default Mesh.bGenerateOverlapEvents = false;

	UPROPERTY()
	FOnSongOfLifeStarted OnSongOfLifeStarted;
	UPROPERTY()
	FOnSongOfLifeEnded OnSongOfLifeEnded;
	
	UPROPERTY()
	FOnPowerfulSongImpactBroadcast OnPowerfulSongImpact;

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		SongReaction.OnPowerfulSongImpact.AddUFunction(this, n"PowerfulSongImpact");
	}

	UFUNCTION(NotBlueprintCallable)
    private void PowerfulSongImpact(FPowerfulSongInfo Info)
    {
		OnPowerfulSongImpact.Broadcast();
    }
}
