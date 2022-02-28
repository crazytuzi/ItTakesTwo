import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
import Vino.Movement.MovementSystemTags;

UCLASS(Abstract)
class AFakeSubmersibleSoil : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent SoilMesh;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		FActorGroundPoundedDelegate GroundPoundDelegate;
		GroundPoundDelegate.BindUFunction(this, n"SoilGroundPounded");
		BindOnActorGroundPounded(this, GroundPoundDelegate);
	}

	UFUNCTION(NotBlueprintCallable)
	void SoilGroundPounded(AHazePlayerCharacter Player)
	{
		if (Player != Game::GetCody())
			return;

		Player.BlockCapabilities(MovementSystemTags::GroundPound, this);
		Player.UnblockCapabilities(MovementSystemTags::GroundPound, this);

		Player.SetViewSize(EHazeViewPointSize::Fullscreen, EHazeViewPointBlendSpeed::Slow);

		DestroyActor();
	}
}