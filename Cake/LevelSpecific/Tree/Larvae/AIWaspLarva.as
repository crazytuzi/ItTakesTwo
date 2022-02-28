import Cake.Weapons.Match.MatchHitResponseComponent;
import Vino.Movement.Components.MovementComponent;
import Cake.Weapons.Sap.SapResponseComponent;
import Cake.LevelSpecific.Tree.Larvae.Behaviours.LarvaBehaviourComponent;
import Cake.LevelSpecific.Tree.Larvae.Movement.LarvaMovementDataComponent;
import Cake.LevelSpecific.Tree.Wasps.Spawning.WaspRespawnerComponent;
import Cake.LevelSpecific.Tree.Larvae.Teams.LarvaMusicTeam;
import Peanuts.Audio.AudioStatics;
import Peanuts.Aiming.AutoAimTarget;
import Cake.Weapons.Sap.SapCustomAttachComponent;

settings AIWaspLarvaDefaultMovementSettings for UMovementSettings
{
	AIWaspLarvaDefaultMovementSettings.MoveSpeed = 400.f;
	AIWaspLarvaDefaultMovementSettings.GravityMultiplier = 6.f;
	AIWaspLarvaDefaultMovementSettings.WalkableSlopeAngle = 40.f;
}

UCLASS(Abstract)
class AAIWaspLarva : AHazeCharacter
{
    UPROPERTY(DefaultComponent)
	UHazeMovementComponent MovementComponent;
	default MovementComponent.DefaultMovementSettings = AIWaspLarvaDefaultMovementSettings;
	default MovementComponent.ControlSideDefaultCollisionSolver = n"LarvaCollisionSolver";
 	default MovementComponent.RemoteSideDefaultCollisionSolver = n"LarvaCollisionSolver";

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;

   	default CapsuleComponent.SetCollisionProfileName(n"NPC");
   	default CapsuleComponent.SetCapsuleRadius(60.f, false);
   	default CapsuleComponent.SetCapsuleHalfHeight(60.f, false);
    default CapsuleComponent.SetRelativeLocation(FVector(0.f, 0.f, 0.f));
	default CapsuleComponent.bGenerateOverlapEvents = false; // Expensive with lots of larvae moving and currently not needed
    default Mesh.SetRelativeLocation(FVector(0.f, 0.f, 0.f));
	default Mesh.CollisionEnabled = ECollisionEnabled::NoCollision;

    UPROPERTY(DefaultComponent)
    ULarvaMovementDataComponent MovementDataComponent;

    UPROPERTY(DefaultComponent)
    USapResponseComponent SapResponseComp;

    UPROPERTY(DefaultComponent)
    UMatchHitResponseComponent MatchResponseComp;

	UPROPERTY(DefaultComponent, Attach = CharacterMesh0)
	UAutoAimTargetComponent AutoAimTargetComp;
	default AutoAimTargetComp.bIsAutoAimEnabled = false;
	default AutoAimTargetComp.RelativeLocation = FVector(10.f, 0.f, 40.f);
	default AutoAimTargetComp.AffectsPlayers = EHazeSelectPlayer::May;

	UPROPERTY(DefaultComponent, Attach = AutoAimTargetComp)
	USapCustomAttachComponent SapAttach;
	default SapAttach.bSapHidden = true;

    UPROPERTY(DefaultComponent, meta = (ShowOnlyInnerProperties))
    ULarvaBehaviourComponent BehaviourComponent;

	UPROPERTY(DefaultComponent)
	UWaspRespawnerComponent RespawnComp;

	UPROPERTY(DefaultComponent)
	UHaze2DPathfindingComponent PathfindingComp;

    // Triggers when we die
	UPROPERTY(Category = "Larva Events")
	FLarvaOnDie OnDie;

	//for audio
	UFUNCTION(BlueprintEvent)
	void BP_OnLarvaDie()
	{}

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		MovementComponent.Setup(CapsuleComponent);

        AddCapability(n"LarvaUpdateStateCapability");
		AddCapability(n"LarvaPathfollowingCapability");
		AddCapability(n"LarvaCrawlMovementCapability");
		AddCapability(n"LarvaLeapMovementCapability");
		//AddCapability(n"LarvaDropMovementCapability");
		AddCapability(n"LarvaLaunchToScenepointCapability");
        AddCapability(n"LarvaSelectTargetCapability");
        AddCapability(n"LarvaDetectSapCapability");
		AddCapability(n"LarvaFallDeathCapability");
        AddCapability(n"LarvaDeathCapability");

        AddCapability(n"LarvaBehaviourHatchCapability");
        AddCapability(n"LarvaBehaviourHoldCapability");
        AddCapability(n"LarvaBehaviourPursueCapability");
        AddCapability(n"LarvaBehaviourDropCapability");
        AddCapability(n"LarvaBehaviourExplodeCapability");
        AddCapability(n"LarvaBehaviourEatCapability");

        // Hook up sappery and matchyness
        SapResponseComp.OnMassAdded.AddUFunction(BehaviourComponent, n"OnSapAdded");
        SapResponseComp.OnMassRemoved.AddUFunction(BehaviourComponent, n"OnSapRemoved");
        SapResponseComp.OnSapExploded.AddUFunction(BehaviourComponent, n"OnSapExploded");
        SapResponseComp.OnSapExplodedProximity.AddUFunction(BehaviourComponent, n"OnSapExplodedProximity");
        MatchResponseComp.OnStickyHit.AddUFunction(BehaviourComponent, n"OnMatchImpact");
        MatchResponseComp.OnNonStickyHit.AddUFunction(BehaviourComponent, n"OnMatchImpact");

		BehaviourComponent.OnDie.AddUFunction(this, n"OnDied");
		BehaviourComponent.OnDie.AddUFunction(RespawnComp, n"UnSpawn");	
		RespawnComp.OnReset.AddUFunction(BehaviourComponent, n"Reset");
		RespawnComp.OnReset.AddUFunction(MovementDataComponent, n"Reset");

		JoinTeam(n"LarvaMusicIntensityTeam", ULarvaMusicTeam::StaticClass());
    }

	UFUNCTION()
	void Hatch(UScenepointComponent HatchPoint)
	{
		MovementDataComponent.HatchPoint = HatchPoint;
		BehaviourComponent.State = ELarvaState::Hatching;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnDied(AHazeActor Larva)
	{
		OnDie.Broadcast(Larva);
		BP_OnLarvaDie();
	}
}
