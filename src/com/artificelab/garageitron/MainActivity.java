package com.artificelab.garageitron;
import java.io.IOException;
import android.os.Bundle;
import android.app.Activity;
import android.view.Menu;
import android.view.View;
import android.widget.Button;
import android.widget.Toast;
import android.os.AsyncTask;
import org.apache.http.HttpResponse;
import org.apache.http.HttpStatus;
import org.apache.http.client.*;
import org.apache.http.client.methods.*;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.util.EntityUtils;
import javax.crypto.SecretKey;
import javax.crypto.Mac;
import android.util.Base64;
// Import get unix time

public class MainActivity extends Activity {

	protected class NetworkTask extends AsyncTask<String, Void, Boolean> {

		@Override
		protected Boolean doInBackground(String... params) {
			HttpClient hc = new DefaultHttpClient();
			HttpPost post = new HttpPost(params[0]);
			try {
				hc.execute(post);
				return true;
			}
			catch(IOException e) {
				e.printStackTrace();
			}
			return false;
		}
		
	}
	
	Button doorButton;
	Button lightButton;
	
	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		setContentView(R.layout.activity_main);
	
		doorButton  = (Button) findViewById(R.id.doorButton);
		lightButton = (Button) findViewById(R.id.lightButton);
		
		doorButton.setOnClickListener(new View.OnClickListener() {
			@Override
			public void onClick(View v) {
				Toast t = Toast.makeText(getApplicationContext(), "Pinging door", Toast.LENGTH_LONG);
				t.show();
				new NetworkTask().execute("URL");
			}
		});
		
		lightButton.setOnClickListener(new View.OnClickListener() {
			@Override
			public void onClick(View v) {
				Toast t = Toast.makeText(getApplicationContext(), "Pinging light", Toast.LENGTH_LONG);
				t.show();
				new NetworkTask().execute("URL");
			}
		});
	}

	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		// Inflate the menu; this adds items to the action bar if it is present.
		getMenuInflater().inflate(R.menu.main, menu);
		return true;
	}
	
}
