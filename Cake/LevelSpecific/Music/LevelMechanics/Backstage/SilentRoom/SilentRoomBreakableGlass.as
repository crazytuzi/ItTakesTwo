import Cake.Environment.Breakable;
import Cake.LevelSpecific.Music.Singing.SongReactionComponent;
import Peanuts.Aiming.AutoAimTarget;

class ASilentRoomBreakableGlass : ABreakableActor
{
	UPROPERTY(DefaultComponent, Attach = BreakableComponent)
	USongReactionComponent SongReaction;

	UPROPERTY(DefaultComponent, Attach = SongReaction)
	UAutoAimTargetComponent AutoAimComp;

	UPROPERTY(DefaultComponent, Attach = SongReaction)
	USphereComponent SphereCollision;
	default SphereCollision.bGenerateOverlapEvents = false;
	default SphereCollision.CollisionProfileName = n"WeaponTraceBlocker";
	default SphereCollision.CanCharacterStepUpOn = ECanBeCharacterBase::ECB_No;
	default SphereCollision.SphereRadius = 180.0f;

	UPROPERTY()
	float DirectionalForceMultiplier = 200.f;

	UPROPERTY()
	float ScatterForce = 10.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SongReaction.OnPowerfulSongImpact.AddUFunction(this, n"PowerfulSongImpact");
	}	

	UFUNCTION()
	void PowerfulSongImpact(FPowerfulSongInfo Info)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Info.Instigator);

		if (Player == nullptr)
			return;

		FBreakableHitData BreakData;
		BreakData.DirectionalForce = Info.Direction * DirectionalForceMultiplier;
		BreakData.HitLocation = GetActorLocation();
		BreakData.ScatterForce = ScatterForce;
		
		BreakableComponent.Break(BreakData);

		SongReaction.ChangeValidActivator(EHazeActivationPointActivatorType::None);
	}
}