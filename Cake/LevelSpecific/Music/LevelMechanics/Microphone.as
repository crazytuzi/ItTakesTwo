import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongImpactComponent;
import Cake.LevelSpecific.Music.LevelMechanics.MiniatureAmplifier;
import Cake.LevelSpecific.Music.Singing.SingingComponent;
import Cake.LevelSpecific.Music.Singing.PowerfulSong.PowerfulSongTags;

event void FOnMicrophoneHitByPowerfulSong(FPowerfulSongInfo Info);
event void FOnAffectedBySongOfLife(FSongOfLifeInfo Info);

UCLASS(Abstract)
class AMicrophone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent MicrophoneMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USongReactionComponent SongReaction;
	default SongReaction.bAbsoluteScale = true;

	UPROPERTY(DefaultComponent, Attach = SongReaction)
	UAutoAimTargetComponent AutoAimComponent;
	default AutoAimComponent.bAbsoluteScale = true;

	UPROPERTY(DefaultComponent, Attach = SongReaction)
	USphereComponent SphereCollision;
	default SphereCollision.bAbsoluteScale = true;
	default SphereCollision.bGenerateOverlapEvents = false;
	default SphereCollision.CollisionProfileName = n"WeaponTraceBlocker";
	default SphereCollision.CanCharacterStepUpOn = ECanBeCharacterBase::ECB_No;
	default SphereCollision.SphereRadius = 128.0f;

	UPROPERTY()
	FOnMicrophoneHitByPowerfulSong OnHitByPowerfulSong;

	UPROPERTY()
	FOnAffectedBySongOfLife eOnStartAffectedBySongOfLife;

	UPROPERTY()
	FOnAffectedBySongOfLife eOnStopAffectedBySongOfLife;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SongReaction.OnPowerfulSongImpact.AddUFunction(this, n"HandlePowerfulSongImpact");
	}

	UFUNCTION()
	void HandlePowerfulSongImpact(FPowerfulSongInfo Info)
	{
		OnHitByPowerfulSong.Broadcast(Info);
	}
}
