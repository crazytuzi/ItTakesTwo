import Vino.Interactions.InteractionComponent;
import Vino.PlayerHealth.PlayerHealthStatics;
class ACourtyardHorse : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSkeletalMeshComponentBase Mesh;

	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractionComp;

	UPROPERTY()
	UAnimSequence HorseAnimation;

	UPROPERTY()
	TPerPlayer<UAnimSequence> PlayerAnimation;

	default SetActorTickEnabled(false);

	AHazePlayerCharacter InteractingPlayer;

	float PlayerDeathTimer = 0.92f;
	float DeathTimer = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnActivated.AddUFunction(this, n"OnInteracted");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (InteractingPlayer == nullptr)
			return;

		DeathTimer += DeltaSeconds;

		if (InteractingPlayer.HasControl() && DeathTimer >= PlayerDeathTimer)
			NetKillInteractingPlayer(InteractingPlayer);
	}

	UFUNCTION(NotBlueprintCallable)
    protected void OnInteracted(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		InteractionComp.Disable(n"InUse");
		InteractingPlayer = Player;
		DeathTimer = 0.f;
		
		if (HorseAnimation != nullptr)
		{
			FHazePlaySlotAnimationParams HorseAnim;
			HorseAnim.Animation = HorseAnimation;
			Mesh.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), HorseAnim);
		}

		if (PlayerAnimation[Player] != nullptr)
			Player.PlayEventAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), PlayerAnimation[Player]);

		SetActorTickEnabled(true);
    }

	UFUNCTION(NetFunction)
	void NetKillInteractingPlayer(AHazePlayerCharacter Player)
	{
		KillPlayer(Player);
		InteractingPlayer = nullptr;
		InteractionComp.Enable(n"InUse");
		SetActorTickEnabled(false);
	}
}