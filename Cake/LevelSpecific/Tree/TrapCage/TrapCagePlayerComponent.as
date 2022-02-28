import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.Tree.TrapCage.TrapCageActor;
import Cake.Weapons.Sap.SapWeaponStatics;
import Cake.Weapons.Match.MatchWeaponStatics;

enum ETrapCageState
{
	Outside,
	Entering,
	Inside,
	Exiting,
	MAX
}

delegate void FTrapCagePlayerComponentStateChange(ETrapCageState NewSate);

UCLASS(Abstract)
class ATrapCagePlayerActorn : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USphereComponent Root;
	default Root.SetCollisionProfileName(n"PlayerCharacter");
	default Root.bGenerateOverlapEvents = false;
	default Root.SetSimulatePhysics(true);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;
	default Mesh.RelativeLocation = FVector(0.f, 0.f, 1110.f);
	default Mesh.SetCollisionProfileName(n"NoCollision");
	default Mesh.bGenerateOverlapEvents = false;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent Disable;
	default Disable.bDisabledAtStart = true;

	UPROPERTY()
	UNiagaraSystem ActornExplosion;
}

class UTrapCagePlayerComponent : UActorComponent
{
	UPROPERTY(Category = "Animation")
	UHazeLocomotionFeatureBase FreeFlyAsset;

	UPROPERTY(Category = "Animation")
	FHazePlaySlotAnimationParams Electrify;
	default Electrify.bLoop = true;

	UPROPERTY()
	TSubclassOf<ATrapCagePlayerActorn> ActornType;

	UPROPERTY(Transient)
	FTrapCagePlayerComponentStateChange OnStateChange;

	private ETrapCageState CurrentState = ETrapCageState::Outside;
	private UHazeSplineComponent Spline;
	private ATrapCage TrapActor;
	private	ASapWeaponContainer SapContainer;
	private UStaticMeshComponent Quiver;

	UFUNCTION()
	void Initialize(ATrapCage _TrapActor, UHazeSplineComponent _Spline, FTrapCagePlayerComponentStateChange _OnStateChange)
	{
		TrapActor = _TrapActor;
		Spline = _Spline;
		CurrentState = ETrapCageState::Entering;
		OnStateChange = _OnStateChange;
		OnStateChange.Execute(CurrentState);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if(CurrentState != ETrapCageState::Outside)
		{
			SetOutsideState();
		}
	}

	UFUNCTION()
	void Eject()
	{
		CurrentState = ETrapCageState::Exiting;
		OnStateChange.Execute(CurrentState);
	}

	void SetInsideState()
	{
		auto Player = Cast<AHazePlayerCharacter>(Owner);
		
		if(Player.IsCody())
		{
			SapContainer = GetEquippedSapWeaponContainer();
			if(SapContainer != nullptr)
				SapContainer.SetActorHiddenInGame(true);
		}
		
		CurrentState = ETrapCageState::Inside;
		OnStateChange.Execute(CurrentState);
	}

	void SetOutsideState()
	{
		if(SapContainer != nullptr)
			SapContainer.SetActorHiddenInGame(false);
			
		CurrentState = ETrapCageState::Outside;
		OnStateChange.Execute(CurrentState);
	}


	ETrapCageState GetEnterExitState() const property
	{
		return CurrentState;
	}

	ETrapStage GetTrapState() const property
	{
		if(TrapActor == nullptr)
			return ETrapStage::None;

		return TrapActor.CurrentState;
	}

	UHazeSplineComponent GetEnterExitSpline() const property
	{
		return Spline;
	}

	ATrapCage GetTrapCage() const property
	{
		return TrapActor;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)	
	{
		if(CurrentState != ETrapCageState::Outside)
		{
			auto Player = Cast<AHazePlayerCharacter>(Owner);
			Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_Player_IsInsideGlass", 0.f);
		}
	}
}