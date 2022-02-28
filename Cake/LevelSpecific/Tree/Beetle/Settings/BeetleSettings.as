UCLASS(Meta = (ComposeSettingsOnto = "UBeetleSettings"))
class UBeetleSettings : UHazeComposableSettings
{
	// Beetle is subdued and can be mounted after taking this many hits
    UPROPERTY(Category = "BeetleBehaviour|Health")
	int HitPoints = 50;

	// How far away ground explosions can affect beetle
    UPROPERTY(Category = "BeetleBehaviour|Health")
	float GroundExplosionRadius = 100.f;

	// How far below can ground explosion be to affect beetle
    UPROPERTY(Category = "BeetleBehaviour|Health")
	float GroundExplosionMaxHeight = 300.f;

	// Fow how long beetle will be stunned when taking damage
    UPROPERTY(Category = "BeetleBehaviour|Health")
	float DamageStunDuration = 3.f;

	// Only damage greater than or equal to this amount will penetrate beetle shell to do any actual damage
    UPROPERTY(Category = "BeetleBehaviour|Health")
	float MinDamage = 11.f;

	// Only damage greater than this amount will stun beetle
    UPROPERTY(Category = "BeetleBehaviour|Health")
	float StunMinDamage = 11.f;

	// We'll only take the highest amount of any damage during a this number of seconds
    UPROPERTY(Category = "BeetleBehaviour|Health")
	float DamageBatchDuration = 3.f;

	// Fow how long beetle will be stunned when smashing an obstacle
	UPROPERTY(Category = "BeetleBehaviour|Health")
	float DestroyObstacleStunDuration = 0.f;

	// Beetle will turn towards target for at least this long before charging
    UPROPERTY(Category = "BeetleBehaviour|Pursue")
	float FaceTargetDuration = 0.8f;

	// Duration of turn during charge
    UPROPERTY(Category = "BeetleBehaviour|Attack")
	float ChargeTurnDuration = 2.f;

	// Max duration of a charge
    UPROPERTY(Category = "BeetleBehaviour|Attack")
	float ChargeDuration = 10.f;

	// Min duration of a charge where we will turn towards target
    UPROPERTY(Category = "BeetleBehaviour|Attack")
	float ChargeHomingMinDuration = 1.f;

	// If past min homing duration we will charge in a straight line when target is within this distance
    UPROPERTY(Category = "BeetleBehaviour|Attack")
	float ChargeStopHomingRange = 1000.f;

	// Target speed of charge when homing
    UPROPERTY(Category = "BeetleBehaviour|Attack")
	float HomingChargeSpeed = 2500.f;

	// Target speed when charging in a straight line
    UPROPERTY(Category = "BeetleBehaviour|Attack")
	float StraightChargeSpeed = 2500.f;

	// Radius from attack center within which we can hit players
    UPROPERTY(Category = "BeetleBehaviour|Attack")
	float AttackHitRadius = 250.f;	

	// Offset from center of capsule which attack detection radius is centered on
    UPROPERTY(Category = "BeetleBehaviour|Attack")
	FVector AttackCenterOffset = FVector(200.f,0.f,-300.f);

	// How hard attack hits
    UPROPERTY(Category = "BeetleBehaviour|Attack")
	float AttackForce = 2000.f;

	// When we've stopped homing we will consider ourselves to have missed the target if it's beyond this angle from forward vector
    UPROPERTY(Category = "BeetleBehaviour|Attack")
	float MissAngle = 60.f;

	// If true, we will always use the next queued special attack when taking damage
    UPROPERTY(Category = "BeetleBehaviour|Attack")
	bool bUseSpecialAttackWhenDamaged = true;

    UPROPERTY(Category = "BeetleBehaviour|Attack")
	bool bAdditionalAttackRecoveryWhenPlayerKilled = false;

	// When stompong or pouncing, we can hit player with this radius from offset
	UPROPERTY(Category = "BeetleBehaviour|Stomp")
	float StompRadius = 400.f;

	// Stomp hit detection center offset in actor space
	UPROPERTY(Category = "BeetleBehaviour|Stomp")
	FVector StompOffset = FVector(0.f, 0.f, 0.f);

	// We never pounce until health has been reduced by at least this fraction
	UPROPERTY(Category = "BeetleBehaviour|Pounce")
	float PounceStartHealthFraction = 0.7f;

	// We never pounce if target is closer than this
	UPROPERTY(Category = "BeetleBehaviour|Pounce")
	float PounceMinRange = 2000.f;

	// How many regular charges we do in between every pounce
	UPROPERTY(Category = "BeetleBehaviour|Pounce")
	int PounceInterval = 2;

	// How fast we pounce.
	UPROPERTY(Category = "BeetleBehaviour|Pounce")
	float PounceSpeed = 5000.f;

	// We never mulit-slam until health has been reduced by at least this fraction
	UPROPERTY(Category = "BeetleBehaviour|Pounce")
	float MultiSlamStartHealthFraction = 0.8f;

	// How many slams we do in the multi-slam!
	UPROPERTY(Category = "BeetleBehaviour|MultiSlam")
	int MultiSlamCount = 3;

	// How many normal charges we do inbetween every multi-slam
	UPROPERTY(Category = "BeetleBehaviour|MultiSlam")
	int MultiSlamInterval = 2;
	
	// Only do multi slam if target is within this range
	UPROPERTY(Category = "BeetleBehaviour|Pounce")
	float MultiSlamMaxRange = 1000000.f;

	// Angle from our forward direction vs reverse impact normal within which we can destroy obstacles
    UPROPERTY(Category = "BeetleBehaviour|Destruction")
	float DestructionAngle = 140.f;

	// Component to which the health bar is attached
	UPROPERTY(Category = "GUI")
	FName HealthBarAttachComponent = n"Root";

	// Socket to which health bar is attached
	UPROPERTY(Category = "GUI")
	FName HealthBarAttachSocket = n"Head";

	// Offset of health bar
	UPROPERTY(Category = "GUI")
	FVector HealthBarOffset = FVector(0.f, 0.f, 600.f);

	UPROPERTY(Category = "Shockwave")
	FVector ShockwaveRelativeOrigin = FVector(0.f, 0.f, 50.f);

	UPROPERTY(Category = "Shockwave")
	float ShockwaveStartRadius = 200.f;

	UPROPERTY(Category = "Shockwave")
	float ShockwaveThickness = 100.f;

	UPROPERTY(Category = "Shockwave")
	float ShockwaveExpansionSpeed = 2000.f;

	UPROPERTY(Category = "Shockwave")
	float ShockwaveDuration = 3.f;
}
