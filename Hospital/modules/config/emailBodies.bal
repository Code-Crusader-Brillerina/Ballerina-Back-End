public function sendOTPEmail(string otp) returns json {
    string subject = "Your One-Time Password (OTP) for Halgoes Hospital";

    string message = string `
        <html>
          <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <h2 style="color: #2E86C1;">Halgoes Hospital Security Verification</h2>
            <p>Dear User,</p>
            <p>To complete your verification, please use the following One-Time Password (OTP):</p>
            
            <div style="font-size: 22px; font-weight: bold; color: #D35400; margin: 20px 0;">
              ${otp}
            </div>

            <p>This OTP is valid for <b>5 minutes</b>. Please do not share this code with anyone.</p>
            
            <p>If you did not request this, please ignore this email or contact our support team immediately.</p>
            
            <p>Best Regards,<br>
            <b>Halgoes Hospital Security Team</b></p>
          </body>
        </html>`;

    return {
        "subject": subject,
        "message": message
    };
}


public function addDoctorEmail(string username,string email,string password)returns json{
    string subject = string `Welcome to Halgoes hospital Your Doctor Account is Ready`;

    string message=string `
        <html>
          <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <h2 style="color: #2E86C1;">Welcome to Halgoes hospital</h2>
            <p>Dear Dr. ${username},</p>
            <p>Your doctor account has been successfully created in our system.</p>

            <h3>Account Details:</h3>
            <ul>
              <li><b>Email:</b> ${email}</li>
              <li><b>Password:${password}</b> (the one admin set during registration)</li>
            </ul>

            <p>Please log in to your dashboard and remember to change your password after your first login.</p>
            <p>If you have any questions, feel free to contact our support team.</p>

            <p>Best Regards,<br>
            <b>Halgoes hospital Administration</b></p>
          </body>
        </html>
    `;
    return {
        "subject":subject,
        "message":message
    };
}

public function addPharmacyEmail(string pharmacyName, string email, string password) returns json {
    string subject = "Welcome to Halgoes Hospital – Your Pharmacy Account is Ready";

    string message =string `
        <html>
          <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <h2 style="color: #2E86C1;">Welcome to Halgoes Hospital</h2>
            <p>Dear ${pharmacyName},</p>
            <p>Your pharmacy account has been successfully created in our system.</p>

            <h3>Account Details:</h3>
            <ul>
              <li><b>Email:</b> ${email}</li>
              <li><b>Password:</b> ${password} (the one admin set during registration)</li>
            </ul>

            <p>Please log in to your pharmacy dashboard and remember to change your password after your first login.</p>
            <p>If you have any questions, feel free to contact our support team.</p>

            <p>Best Regards,<br>
            <b>Halgoes Hospital Administration</b></p>
          </body>
        </html>`;

    return {
        "subject": subject,
        "message": message
    };
}

public function deleteDoctorEmail(string username, string email) returns json {
    string subject = string `Halgoes Hospital – Doctor Account Deleted`;

    string message = string `
        <html>
          <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <h2 style="color: #C0392B;">Halgoes Hospital</h2>
            <p>Dear Dr. ${username},</p>
            <p>We would like to inform you that your doctor account associated with the email <b>${email}</b> has been removed from our system.</p>

            <p>If you believe this was a mistake or need further clarification, please contact our administration team immediately.</p>

            <p>Best Regards,<br>
            <b>Halgoes Hospital Administration</b></p>
          </body>
        </html>
    `;

    return {
        "subject": subject,
        "message": message
    };
}

public function deletePharmacyEmail(string pharmacyName, string email) returns json {
    string subject = string `Halgoes Hospital – Pharmacy Account Deleted`;

    string message = string `
        <html>
          <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <h2 style="color: #C0392B;">Halgoes Hospital</h2>
            <p>Dear ${pharmacyName},</p>
            <p>We would like to inform you that your pharmacy account associated with the email <b>${email}</b> has been removed from our system.</p>

            <p>If you believe this was a mistake or need further clarification, please contact our administration team immediately.</p>

            <p>Best Regards,<br>
            <b>Halgoes Hospital Administration</b></p>
          </body>
        </html>
    `;

    return {
        "subject": subject,
        "message": message
    };
}

public function paymentEmail(string username, string email, string amount, string date, string invoiceId) returns json {
    string subject = string `Halgoes Hospital – Payment Confirmation (Invoice #${invoiceId})`;

    string message = string `
        <html>
          <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
            <h2 style="color: #27AE60;">Payment Confirmation</h2>
            <p>Dear ${username},</p>
            <p>We have received your payment successfully. Below are the details of your transaction:</p>

            <h3>Payment Details:</h3>
            <ul>
              <li><b>Invoice ID:</b> ${invoiceId}</li>
              <li><b>Amount:</b> ${amount}</li>
              <li><b>Date:</b> ${date}</li>
              <li><b>Email:</b> ${email}</li>
            </ul>

            <p>Thank you for your payment. Please keep this email as confirmation for your records.</p>
            <p>If you have any questions regarding this payment, please contact our billing department.</p>

            <p>Best Regards,<br>
            <b>Halgoes Hospital Finance Team</b></p>
          </body>
        </html>
    `;

    return {
        "subject": subject,
        "message": message
    };
}

