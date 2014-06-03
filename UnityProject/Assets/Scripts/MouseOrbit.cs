using UnityEngine;

//[ExecuteInEditMode]
public class MouseOrbit : MonoBehaviour
{
	public Vector3 target;

	
	public float xSpeed = 250.0f;
	public float ySpeed = 120.0f;
	
	public float yMinLimit = -20f;
	public float yMaxLimit = 80f;
	
	private float x = 0.0f;
	private float y = 0.0f;
	private float distance = 0.0f;

	void Start () 
	{
		var angles = transform.eulerAngles;
		x = angles.y;
		y = angles.x;

		distance = Mathf.Abs (transform.position.z);
	}
	
	void LateUpdate () 
	{
		if (Input.GetMouseButton(0))
		{
			x += Input.GetAxis("Mouse X") * xSpeed * 0.02f;
			y -= Input.GetAxis("Mouse Y") * ySpeed * 0.02f; 		
			y = ClampAngle(y, yMinLimit, yMaxLimit);            
		}
		
		if (Input.GetAxis("Mouse ScrollWheel") > 0.0f) // forward
		{
			distance++;
		}
		if (Input.GetAxis("Mouse ScrollWheel") < 0.0f) // back
		{
			distance--;
		}  
		
		var rotation = Quaternion.Euler(y, x, 0.0f);
		var position = rotation * new Vector3(0.0f, 0.0f, -distance) + target;
		
		transform.rotation = rotation;
		transform.position = position;
	}
	
	private float ClampAngle (float angle, float min, float max)
	{
		if (angle < -360.0f)
			angle += 360.0f;

		if (angle > 360.0f)
			angle -= 360.0f;

		return Mathf.Clamp (angle, min, max);
	}
}
