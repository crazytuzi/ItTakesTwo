import Vino.Movement.MovementSettings;
import Cake.Weapons.Sap.SapResponseComponent;
import Cake.Weapons.Match.MatchHitResponseComponent;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Cake.LevelSpecific.Tree.Wasps.Spawning.WaspRespawnerComponent;
import Cake.LevelSpecific.Tree.Wasps.Health.WaspHealthComponent;
import Cake.LevelSpecific.Tree.Wasps.Animation.WaspAnimationComponent;
import Cake.LevelSpecific.Tree.Wasps.Teams.WaspMusicTeam;

void AddCommonWaspCapabilities(AHazeActor Wasp)
{
	Wasp.AddCapability(n"WaspUpdateBehaviourStateCapability");
	Wasp.AddCapability(n"WaspFlyingRotationCapability");
	Wasp.AddCapability(n"WaspFlyingMovementCapability");
	Wasp.AddCapability(n"WaspFlyAlongSplineMovementCapability");
	Wasp.AddCapability(n"WaspDeathCapability");
	Wasp.AddCapability(n"WaspTakeDamageCapability");
	Wasp.AddCapability(n"WaspSapRemovalCapability");
	Wasp.AddCapability(n"WaspThreeShotAnimationCapability");
	Wasp.AddCapability(n"WaspSingleAnimationCapability");
}

settings AIWaspDefaultMovementSettings for UMovementSettings
{
	AIWaspDefaultMovementSettings.MoveSpeed = 1000.f;
	AIWaspDefaultMovementSettings.GravityMultiplier = 0.f;	
	AIWaspDefaultMovementSettings.WalkableSlopeAngle = 89.99f;
	AIWaspDefaultMovementSettings.ActorMaxFallSpeed = BIG_NUMBER;
	AIWaspDefaultMovementSettings.StepUpAmount = 40.f;
	AIWaspDefaultMovementSettings.CeilingAngle = 89.99f;
	AIWaspDefaultMovementSettings.VerticalForceAirPushOffThreshold = 0.f;
}

void SetupCommonWaspDelegates(AHazeActor Wasp)
{
	USapResponseComponent SapResponseComp = USapResponseComponent::Get(Wasp);
	UMatchHitResponseComponent MatchResponseComp = UMatchHitResponseComponent::Get(Wasp);
	UWaspBehaviourComponent BehaviourComponent = UWaspBehaviourComponent::Get(Wasp);
	UWaspRespawnerComponent RespawnComp = UWaspRespawnerComponent::Get(Wasp);
	UWaspAnimationComponent AnimComp = UWaspAnimationComponent::Get(Wasp);
	UWaspHealthComponent HealthComp = UWaspHealthComponent::Get(Wasp);

	// Hook up sappery and matchyness
	SapResponseComp.OnMassAdded.AddUFunction(HealthComp, n"OnSapMassAdded");
	SapResponseComp.OnMassRemoved.AddUFunction(HealthComp, n"OnSapMassRemoved");
	SapResponseComp.OnSapExploded.AddUFunction(HealthComp, n"OnSapExploded");
	SapResponseComp.OnSapExplodedProximity.AddUFunction(HealthComp, n"OnSapExplodedProximity");
	MatchResponseComp.OnStickyHit.AddUFunction(HealthComp, n"OnMatchImpact");
	MatchResponseComp.OnNonStickyHit.AddUFunction(HealthComp, n"OnMatchImpact");

	HealthComp.OnDie.AddUFunction(Wasp, n"OnDied");
	BehaviourComponent.OnUnspawn.AddUFunction(RespawnComp, n"UnSpawn");	
	RespawnComp.OnReset.AddUFunction(BehaviourComponent, n"Reset");
	RespawnComp.OnReset.AddUFunction(AnimComp, n"Reset");
	RespawnComp.OnReset.AddUFunction(HealthComp, n"Reset");

	Wasp.JoinTeam(n"WaspMusicIntensityTeam", UWaspMusicTeam::StaticClass());
}