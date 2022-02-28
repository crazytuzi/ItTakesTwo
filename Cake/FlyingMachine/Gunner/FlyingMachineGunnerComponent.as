import Cake.FlyingMachine.FlyingMachine;
import Cake.FlyingMachine.Turret.FlyingMachineTurret;
import Peanuts.Aiming.AutoAimTarget;

class UFlyingMachineGunnerComponent : UActorComponent
{
	AFlyingMachineTurret CurrentTurret;
	AActor ButtonMashSquirrel;
	UHazeCapabilitySheet Sheet;

	FVector TargetAimDirection;

	// The reason we save this separately from the turrets _actual_ forward is to avoid bumpiness
	// from the flying machine turning and whatnot
	FVector CurrentAimDirection;

	UAutoAimTargetComponent AutoAimedTarget;

	float ReloadProgress = 0.f;
}